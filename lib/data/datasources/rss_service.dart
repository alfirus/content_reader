import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:webfeed_plus/webfeed_plus.dart';
import 'package:html/parser.dart' as html_parser;
import '../models/feed.dart';
import '../models/article.dart';

class RssService {
  /// Validate feed URL before adding
  Future<FeedValidationResult> validateFeed(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        return FeedValidationResult(valid: false, error: 'HTTP ${response.statusCode}');
      }
      
      // Try to parse as RSS
      try {
        RssFeed.parse(response.body);
        return FeedValidationResult(valid: true);
      } catch (_) {
        // Try to parse as Atom
        try {
          AtomFeed.parse(response.body);
          return FeedValidationResult(valid: true);
        } catch (_) {
          return FeedValidationResult(valid: false, error: 'Invalid RSS/Atom format');
        }
      }
    } catch (e) {
      return FeedValidationResult(valid: false, error: e.toString());
    }
  }

  /// Fetch multiple feeds in parallel with concurrency limit
  Future<List<Feed>> fetchFeedsParallel(List<Feed> feeds, {int concurrencyLimit = 5}) async {
    final results = <Feed>[];
    final queue = <Future<Feed?>>[];
    
    for (final feed in feeds) {
      queue.add(fetchFeed(feed.url).then((result) {
        if (result != null) {
          results.add(result);
        }
        return result;
      }));
      
      // Process in batches
      if (queue.length >= concurrencyLimit) {
        await Future.wait(queue);
        queue.clear();
      }
    }
    
    // Process remaining
    if (queue.isNotEmpty) {
      await Future.wait(queue);
    }
    
    return results;
  }

  Future<Feed?> fetchFeed(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final body = response.body;
        
        // Try RSS first
        var feed = RssFeed.parse(body);
        return Feed(
          url: url,
          title: feed.title ?? 'Unknown Feed',
          description: feed.description ?? '',
          favicon: feed.image?.url ?? '',
          lastFetched: DateTime.now(),
        );
      }
    } catch (e) {
      // Try Atom if RSS fails
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final body = response.body;
          var feed = AtomFeed.parse(body);
          return Feed(
            url: url,
            title: feed.title ?? 'Unknown Feed',
            description: feed.subtitle ?? '',
            favicon: feed.logo ?? '',
            lastFetched: DateTime.now(),
          );
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<List<Article>> fetchArticles(String url, int feedId) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final body = response.body;
        List<Article> articles = [];

        try {
          // Try RSS
          var rssFeed = RssFeed.parse(body);
          for (var item in rssFeed.items ?? []) {
            // Extract image from various RSS fields
            String? imageUrl;
            
            // Try media:content
            if (item.media?.contents?.isNotEmpty == true) {
              imageUrl = item.media!.contents!.first.url;
            }
            // Try enclosure
            if (imageUrl == null && item.enclosure?.url != null) {
              final enclosureType = item.enclosure?.type ?? '';
              if (enclosureType.startsWith('image/')) {
                imageUrl = item.enclosure!.url;
              }
            }
            // Try media:thumbnail
            if (imageUrl == null && item.media?.thumbnails?.isNotEmpty == true) {
              imageUrl = item.media!.thumbnails!.first.url;
            }
            // Try to extract from content
            if (imageUrl == null && item.content?.value != null) {
              imageUrl = _extractImageFromHtml(item.content!.value!);
            }
            // Try to extract from description
            if (imageUrl == null && item.description != null) {
              imageUrl = _extractImageFromHtml(item.description!);
            }

            articles.add(Article(
              feedId: feedId,
              title: item.title ?? 'No Title',
              link: item.link ?? '',
              content: item.content?.value ?? item.description ?? '',
              summary: item.description ?? '',
              author: item.author ?? item.dc?.creator ?? '',
              published: item.pubDate ?? DateTime.now(),
              imageUrl: imageUrl,
            ));
          }
        } catch (_) {
          // Try Atom
          try {
            var atomFeed = AtomFeed.parse(body);
            for (var entry in atomFeed.items ?? []) {
              String? imageUrl;
              
              // Try media content
              if (entry.media?.contents?.isNotEmpty == true) {
                imageUrl = entry.media!.contents!.first.url;
              }
              // Try links
              if (imageUrl == null && entry.links?.isNotEmpty == true) {
                for (var link in entry.links!) {
                  if (link.type?.startsWith('image/') == true) {
                    imageUrl = link.href;
                    break;
                  }
                }
              }
              // Try to extract from content
              if (imageUrl == null && entry.content != null) {
                imageUrl = _extractImageFromHtml(entry.content!);
              }
              
              articles.add(Article(
                feedId: feedId,
                title: entry.title ?? 'No Title',
                link: entry.links?.isNotEmpty == true ? entry.links!.first.href : '',
                content: entry.content ?? entry.summary ?? '',
                summary: entry.summary ?? '',
                author: entry.authors?.isNotEmpty == true 
                    ? entry.authors!.first.name ?? '' 
                    : '',
                published: entry.updated ?? DateTime.now(),
                imageUrl: imageUrl,
              ));
            }
          } catch (_) {
            return [];
          }
        }

        return articles;
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  String? _extractImageFromHtml(String html) {
    try {
      var document = html_parser.parse(html);
      var imgElements = document.getElementsByTagName('img');
      if (imgElements.isNotEmpty) {
        // Get the first image with a valid src
        for (var img in imgElements) {
          var src = img.attributes['src'];
          if (src != null && src.startsWith('http')) {
            return src;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  String stripHtml(String htmlString) {
    if (htmlString.isEmpty) return '';
    var document = html_parser.parse(htmlString);
    return document.body?.text ?? '';
  }
}

/// Feed validation result
class FeedValidationResult {
  final bool valid;
  final String? error;
  
  FeedValidationResult({required this.valid, this.error});
  
  @override
  String toString() => valid ? 'Valid' : 'Invalid: $error';
}
