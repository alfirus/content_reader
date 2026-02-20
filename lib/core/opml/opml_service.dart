import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';
import '../../data/datasources/database_helper.dart';
import '../../data/models/feed.dart';
import '../../data/models/category.dart';

class OpmlService {
  static final OpmlService instance = OpmlService._();
  OpmlService._();

  /// Export all feeds and categories to OPML format
  Future<String> exportOpml() async {
    final db = DatabaseHelper.instance;
    final feeds = await db.getAllFeeds();
    final categories = await db.getAllCategories();

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<opml version="2.0">');
    buffer.writeln('<head>');
    buffer.writeln('  <title>Content Reader Exports</title>');
    buffer.writeln('  <dateCreated>${DateTime.now().toIso8601String()}</dateCreated>');
    buffer.writeln('  <ownerName>Content Reader Flutter</ownerName>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');

    // Group feeds by category
    final feedsByCategory = <int?, List<Feed>>{};
    for (final feed in feeds) {
      final categoryId = feed.categoryId;
      if (!feedsByCategory.containsKey(categoryId)) {
        feedsByCategory[categoryId] = [];
      }
      feedsByCategory[categoryId]!.add(feed);
    }

    // Write categorized feeds
    for (final category in categories) {
      buffer.writeln('  <outline text="${_escapeXml(category.name)}">');
      final categoryFeeds = feedsByCategory[category.id] ?? [];
      for (final feed in categoryFeeds) {
        buffer.writeln(
          '    <outline type="rss" text="${_escapeXml(feed.title)}" xmlUrl="${_escapeXml(feed.url)}"/>',
        );
      }
      buffer.writeln('  </outline>');
    }

    // Write uncategorized feeds
    final uncategorizedFeeds = feedsByCategory[null] ?? [];
    if (uncategorizedFeeds.isNotEmpty) {
      buffer.writeln('  <outline text="Uncategorized">');
      for (final feed in uncategorizedFeeds) {
        buffer.writeln(
          '    <outline type="rss" text="${_escapeXml(feed.title)}" xmlUrl="${_escapeXml(feed.url)}"/>',
        );
      }
      buffer.writeln('  </outline>');
    }

    buffer.writeln('</body>');
    buffer.writeln('</opml>');

    return buffer.toString();
  }

  /// Save OPML to file
  Future<File> saveOpmlToFile() async {
    final opmlContent = await exportOpml();
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/content_reader_export_$timestamp.opml');
    await file.writeAsString(opmlContent);
    return file;
  }

  /// Import feeds from OPML file
  Future<OpmlImportResult> importOpml(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return OpmlImportResult(
          success: false,
          error: 'File not found',
        );
      }

      final content = await file.readAsString();
      return await _parseOpml(content);
    } catch (e) {
      return OpmlImportResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Import OPML from string
  Future<OpmlImportResult> importOpmlFromString(String content) async {
    try {
      return await _parseOpml(content);
    } catch (e) {
      return OpmlImportResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<OpmlImportResult> _parseOpml(String content) async {
    final db = DatabaseHelper.instance;
    int categoriesCreated = 0;
    int feedsImported = 0;
    int feedsSkipped = 0;
    final errors = <String>[];

    try {
      final document = XmlDocument.parse(content);
      final opmlElement = document.getElement('opml');
      if (opmlElement == null) {
        return OpmlImportResult(
          success: false,
          error: 'Invalid OPML format: missing opml element',
        );
      }

      final bodyElement = opmlElement.getElement('body');
      if (bodyElement == null) {
        return OpmlImportResult(
          success: false,
          error: 'Invalid OPML format: missing body element',
        );
      }

      // Process category outlines
      for (final outline in bodyElement.findElements('outline')) {
        final categoryName = outline.getAttribute('text');
        if (categoryName == null || categoryName.isEmpty) continue;

        // Check if category already exists
        final existingCategories = await db.getAllCategories();
        var category = existingCategories.firstWhere(
          (c) => c.name == categoryName,
          orElse: () => Category(name: categoryName),
        );

        if (category.id == null) {
          // Create new category
          final categoryId = await db.insertCategory(category);
          category = category.copyWith(id: categoryId);
          categoriesCreated++;
        }

        // Process feeds in this category
        for (final feedOutline in outline.findElements('outline')) {
          final feedUrl = feedOutline.getAttribute('xmlUrl');
          final feedTitle = feedOutline.getAttribute('text') ?? 'Unknown Feed';

          if (feedUrl == null || feedUrl.isEmpty) continue;

          // Check if feed already exists
          final existingFeeds = await db.getAllFeeds();
          final feedExists = existingFeeds.any((f) => f.url == feedUrl);

          if (feedExists) {
            feedsSkipped++;
            continue;
          }

          // Create new feed
          final feed = Feed(
            url: feedUrl,
            title: feedTitle,
            categoryId: category.id,
          );
          await db.insertFeed(feed);
          feedsImported++;
        }
      }

      return OpmlImportResult(
        success: true,
        categoriesCreated: categoriesCreated,
        feedsImported: feedsImported,
        feedsSkipped: feedsSkipped,
        errors: errors,
      );
    } catch (e) {
      return OpmlImportResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

/// OPML import result
class OpmlImportResult {
  final bool success;
  final String? error;
  final int categoriesCreated;
  final int feedsImported;
  final int feedsSkipped;
  final List<String> errors;

  OpmlImportResult({
    required this.success,
    this.error,
    this.categoriesCreated = 0,
    this.feedsImported = 0,
    this.feedsSkipped = 0,
    this.errors = const [],
  });

  @override
  String toString() {
    if (success) {
      return 'Imported: $categoriesCreated categories, $feedsImported feeds (skipped $feedsSkipped duplicates)';
    } else {
      return 'Failed: $error';
    }
  }
}
