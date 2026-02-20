import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/feed.dart';
import '../models/article.dart';
import '../models/category.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('content_reader.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE feeds ADD COLUMN categoryId INTEGER');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          color INTEGER DEFAULT 0xFF2196F3
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE articles ADD COLUMN imageUrl TEXT');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color INTEGER DEFAULT 0xFF2196F3
      )
    ''');

    await db.execute('''
      CREATE TABLE feeds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryId INTEGER,
        url TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        favicon TEXT,
        lastFetched INTEGER,
        FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE articles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        feedId INTEGER NOT NULL,
        title TEXT NOT NULL,
        link TEXT NOT NULL,
        content TEXT,
        summary TEXT,
        author TEXT,
        published INTEGER NOT NULL,
        isRead INTEGER DEFAULT 0,
        isSaved INTEGER DEFAULT 0,
        isDownloaded INTEGER DEFAULT 0,
        imageUrl TEXT,
        FOREIGN KEY (feedId) REFERENCES feeds (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  // Category Operations
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap()..remove('id'));
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'name ASC');
    return result.map((map) => Category.fromMap(map)).toList();
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    // Set categoryId to null for feeds in this category
    await db.update('feeds', {'categoryId': null}, where: 'categoryId = ?', whereArgs: [id]);
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Feed Operations
  Future<int> insertFeed(Feed feed) async {
    final db = await database;
    return await db.insert('feeds', feed.toMap()..remove('id'));
  }

  Future<List<Feed>> getAllFeeds() async {
    final db = await database;
    final result = await db.query('feeds', orderBy: 'title ASC');
    return result.map((map) => Feed.fromMap(map)).toList();
  }

  Future<List<Feed>> getFeedsByCategory(int? categoryId) async {
    final db = await database;
    if (categoryId == null) {
      final result = await db.query('feeds', where: 'categoryId IS NULL', orderBy: 'title ASC');
      return result.map((map) => Feed.fromMap(map)).toList();
    }
    final result = await db.query('feeds', where: 'categoryId = ?', whereArgs: [categoryId], orderBy: 'title ASC');
    return result.map((map) => Feed.fromMap(map)).toList();
  }

  Future<int> updateFeed(Feed feed) async {
    final db = await database;
    return await db.update(
      'feeds',
      feed.toMap(),
      where: 'id = ?',
      whereArgs: [feed.id],
    );
  }

  Future<int> deleteFeed(int id) async {
    final db = await database;
    await db.delete('articles', where: 'feedId = ?', whereArgs: [id]);
    return await db.delete('feeds', where: 'id = ?', whereArgs: [id]);
  }

  // Article Operations
  Future<int> insertArticle(Article article) async {
    final db = await database;
    return await db.insert('articles', article.toMap()..remove('id'));
  }

  Future<List<Article>> getAllArticles({
    int limit = 50,
    int offset = 0,
    String? searchQuery,
  }) async {
    final db = await database;
    String query = 'SELECT * FROM articles';
    List<dynamic> args = [];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query += ' WHERE title LIKE ? OR content LIKE ? OR summary LIKE ?';
      final likeQuery = '%$searchQuery%';
      args.addAll([likeQuery, likeQuery, likeQuery]);
      query += ' ORDER BY published DESC LIMIT ? OFFSET ?';
      args.addAll([limit, offset]);
    } else {
      query += ' ORDER BY published DESC LIMIT ? OFFSET ?';
      args.addAll([limit, offset]);
    }
    
    final result = await db.rawQuery(query, args);
    return result.map((map) => Article.fromMap(map)).toList();
  }
  
  /// Get total article count (for pagination)
  Future<int> getArticleCount({String? searchQuery}) async {
    final db = await database;
    String query = 'SELECT COUNT(*) as count FROM articles';
    List<dynamic> args = [];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query += ' WHERE title LIKE ? OR content LIKE ? OR summary LIKE ?';
      final likeQuery = '%$searchQuery%';
      args.addAll([likeQuery, likeQuery, likeQuery]);
    }
    
    final result = await db.rawQuery(query, args);
    return result.first['count'] as int? ?? 0;
  }

  Future<List<Article>> getArticlesByFeed(int feedId) async {
    final db = await database;
    final result = await db.query(
      'articles',
      where: 'feedId = ?',
      whereArgs: [feedId],
      orderBy: 'published DESC',
    );
    return result.map((map) => Article.fromMap(map)).toList();
  }

  Future<List<Article>> getSavedArticles() async {
    final db = await database;
    final result = await db.query(
      'articles',
      where: 'isSaved = ?',
      whereArgs: [1],
      orderBy: 'published DESC',
    );
    return result.map((map) => Article.fromMap(map)).toList();
  }

  Future<List<Article>> getUnreadArticles() async {
    final db = await database;
    final result = await db.query(
      'articles',
      where: 'isRead = ?',
      whereArgs: [0],
      orderBy: 'published DESC',
    );
    return result.map((map) => Article.fromMap(map)).toList();
  }

  Future<int> updateArticle(Article article) async {
    final db = await database;
    return await db.update(
      'articles',
      article.toMap(),
      where: 'id = ?',
      whereArgs: [article.id],
    );
  }

  Future<int> deleteArticle(int id) async {
    final db = await database;
    return await db.delete('articles', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getUnreadCount(int feedId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM articles WHERE feedId = ? AND isRead = 0',
      [feedId],
    );
    return result.first['count'] as int;
  }

  Future<int> getUnreadCountByCategory(int categoryId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM articles a JOIN feeds f ON a.feedId = f.id WHERE f.categoryId = ? AND a.isRead = 0',
      [categoryId],
    );
    return result.first['count'] as int;
  }

  // Settings Operations
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }
}
