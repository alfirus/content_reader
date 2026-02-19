import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../../data/datasources/database_helper.dart';
import '../../data/models/feed.dart';
import '../../data/models/article.dart';
import '../../data/models/category.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  HttpServer? _server;
  final int port = 1212;
  String? _apiKey;

  static const String _apiKeySetting = 'api_key';
  static const String _apiKeyGeneratedSetting = 'api_key_generated';

  Future<void> start() async {
    // Initialize or get API key
    await _initApiKey();
    
    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_corsMiddleware())
        .addMiddleware(_authMiddleware())
        .addHandler(_router);

    _server = await shelf_io.serve(handler, 'localhost', port);
    print('API Server running on http://localhost:$port');
    print('API Key: $_apiKey');
  }

  Future<void> _initApiKey() async {
    final db = DatabaseHelper.instance;
    
    // Check if API key already exists
    String? existingKey = await db.getSetting(_apiKeySetting);
    
    if (existingKey != null && existingKey.isNotEmpty) {
      _apiKey = existingKey;
    } else {
      // Generate new API key on first use
      _apiKey = _generateApiKey();
      await db.setSetting(_apiKeySetting, _apiKey!);
      await db.setSetting(_apiKeyGeneratedSetting, DateTime.now().toIso8601String());
      print('New API Key generated: $_apiKey');
    }
  }

  String _generateApiKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(32, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
  }

  String? get apiKey => _apiKey;

  /// Regenerate API key (callable from UI)
  Future<String> regenerateApiKey() async {
    final db = DatabaseHelper.instance;
    _apiKey = _generateApiKey();
    await db.setSetting(_apiKeySetting, _apiKey!);
    await db.setSetting(_apiKeyGeneratedSetting, DateTime.now().toIso8601String());
    return _apiKey!;
  }

  Middleware _corsMiddleware() {
    return createMiddleware(
      requestHandler: (request) {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        return null;
      },
      responseHandler: (response) {
        return response.change(headers: _corsHeaders);
      },
    );
  }

  // API Key authentication middleware
  Middleware _authMiddleware() {
    return createMiddleware(
      requestHandler: (request) {
        // Skip auth for health check
        if (request.url.path == 'health') {
          return null;
        }
        
        final authHeader = request.headers['authorization'];
        if (authHeader == null || authHeader != 'Bearer $_apiKey') {
          return Response.unauthorized(
            jsonEncode({'error': 'Invalid or missing API key'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
        return null;
      },
    );
  }

  static const _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
  };

  // Health check (no auth required)
  static Future<Response> _healthCheck(Request request) async {
    final db = DatabaseHelper.instance;
    final apiKeyGenerated = await db.getSetting('api_key_generated');
    
    return Response.ok(
      jsonEncode({
        'status': 'ok', 
        'service': 'content_reader_api',
        'api_key_generated': apiKeyGenerated != null,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // Get API key (only available on first run before it's set)
  static Future<Response> _getApiKey(Request request) async {
    final db = DatabaseHelper.instance;
    final apiKey = await db.getSetting('api_key');
    
    if (apiKey == null || apiKey.isEmpty) {
      return Response.notFound(
        jsonEncode({'error': 'API key not found'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    
    return Response.ok(
      jsonEncode({'api_key': apiKey}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // Regenerate API key
  static Future<Response> _regenerateApiKey(Request request) async {
    try {
      final db = DatabaseHelper.instance;
      final random = Random.secure();
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
      final newKey = List.generate(32, (index) => chars[random.nextInt(chars.length)]).join();
      
      await db.setSetting('api_key', newKey);
      
      return Response.ok(
        jsonEncode({'api_key': newKey, 'message': 'API key regenerated'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  // ============ CATEGORIES ============

  static Future<Response> _getCategories(Request request) async {
    try {
      final db = DatabaseHelper.instance;
      final categories = await db.getAllCategories();
      return Response.ok(
        jsonEncode(categories.map((c) => c.toMap()).toList()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  static Future<Response> _createCategory(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final db = DatabaseHelper.instance;
      
      final category = Category(
        name: data['name'],
        color: data['color'] ?? 0xFF2196F3,
      );
      
      final id = await db.insertCategory(category);
      return Response.ok(
        jsonEncode({'id': id, 'message': 'Category created'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  static Future<Response> _updateCategory(Request request, String id) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final db = DatabaseHelper.instance;
      
      final category = Category(
        id: int.parse(id),
        name: data['name'],
        color: data['color'] ?? 0xFF2196F3,
      );
      
      await db.updateCategory(category);
      return Response.ok(
        jsonEncode({'message': 'Category updated'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  static Future<Response> _deleteCategory(Request request, String id) async {
    try {
      final db = DatabaseHelper.instance;
      await db.deleteCategory(int.parse(id));
      return Response.ok(
        jsonEncode({'message': 'Category deleted'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  // ============ FEEDS ============

  static Future<Response> _getFeeds(Request request) async {
    try {
      final db = DatabaseHelper.instance;
      final feeds = await db.getAllFeeds();
      return Response.ok(
        jsonEncode(feeds.map((f) => f.toMap()).toList()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  static Future<Response> _createFeed(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final db = DatabaseHelper.instance;
      
      final feed = Feed(
        url: data['url'],
        title: data['title'],
        description: data['description'] ?? '',
        favicon: data['favicon'] ?? '',
        categoryId: data['categoryId'],
      );
      
      final id = await db.insertFeed(feed);
      return Response.ok(
        jsonEncode({'id': id, 'message': 'Feed created'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  static Future<Response> _updateFeed(Request request, String id) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final db = DatabaseHelper.instance;
      
      final feeds = await db.getAllFeeds();
      final existing = feeds.firstWhere((f) => f.id == int.parse(id));
      
      final feed = Feed(
        id: int.parse(id),
        url: data['url'] ?? existing.url,
        title: data['title'] ?? existing.title,
        description: data['description'] ?? existing.description,
        favicon: data['favicon'] ?? existing.favicon,
        categoryId: data['categoryId'] ?? existing.categoryId,
      );
      
      await db.updateFeed(feed);
      return Response.ok(
        jsonEncode({'message': 'Feed updated'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  static Future<Response> _deleteFeed(Request request, String id) async {
    try {
      final db = DatabaseHelper.instance;
      await db.deleteFeed(int.parse(id));
      return Response.ok(
        jsonEncode({'message': 'Feed deleted'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  // ============ ARTICLES ============

  static Future<Response> _getArticles(Request request) async {
    try {
      final db = DatabaseHelper.instance;
      final articles = await db.getAllArticles();
      return Response.ok(
        jsonEncode(articles.map((a) => a.toMap()).toList()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  static Future<Response> _getSavedArticles(Request request) async {
    try {
      final db = DatabaseHelper.instance;
      final articles = await db.getSavedArticles();
      return Response.ok(
        jsonEncode(articles.map((a) => a.toMap()).toList()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  static Future<Response> _getUnreadCount(Request request) async {
    try {
      final db = DatabaseHelper.instance;
      final articles = await db.getUnreadArticles();
      return Response.ok(
        jsonEncode({'count': articles.length}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  static Future<Response> _updateArticle(Request request, String id) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final db = DatabaseHelper.instance;
      
      final articles = await db.getAllArticles();
      final existing = articles.firstWhere((a) => a.id == int.parse(id));
      
      final article = Article(
        id: int.parse(id),
        feedId: data['feedId'] ?? existing.feedId,
        title: data['title'] ?? existing.title,
        link: data['link'] ?? existing.link,
        content: data['content'] ?? existing.content,
        summary: data['summary'] ?? existing.summary,
        author: data['author'] ?? existing.author,
        published: data['published'] != null 
            ? DateTime.parse(data['published']) 
            : existing.published,
        isRead: data['isRead'] ?? existing.isRead,
        isSaved: data['isSaved'] ?? existing.isSaved,
        isDownloaded: data['isDownloaded'] ?? existing.isDownloaded,
        imageUrl: data['imageUrl'] ?? existing.imageUrl,
      );
      
      await db.updateArticle(article);
      return Response.ok(
        jsonEncode({'message': 'Article updated'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  static Future<Response> _deleteArticle(Request request, String id) async {
    try {
      final db = DatabaseHelper.instance;
      await db.deleteArticle(int.parse(id));
      return Response.ok(
        jsonEncode({'message': 'Article deleted'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  // ============ ROUTES ============

  static final _router = Router()
    // Health & API Key (no auth)
    ..get('/health', _healthCheck)
    ..get('/api-key', _getApiKey)
    ..post('/api-key/regenerate', _regenerateApiKey)
    
    // Categories
    ..get('/categories', _getCategories)
    ..post('/categories', _createCategory)
    ..put('/categories/<id>', _updateCategory)
    ..delete('/categories/<id>', _deleteCategory)
    
    // Feeds
    ..get('/feeds', _getFeeds)
    ..post('/feeds', _createFeed)
    ..put('/feeds/<id>', _updateFeed)
    ..delete('/feeds/<id>', _deleteFeed)
    
    // Articles
    ..get('/articles', _getArticles)
    ..get('/articles/saved', _getSavedArticles)
    ..get('/articles/unread/count', _getUnreadCount)
    ..put('/articles/<id>', _updateArticle)
    ..delete('/articles/<id>', _deleteArticle);
}
