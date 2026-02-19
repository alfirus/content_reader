import 'package:http/http.dart' as http;
import 'package:webfeed_plus/webfeed_plus.dart';
import 'package:html/parser.dart' as html_parser;

void main() async {
  final url = 'https://www.lowyat.net/feed/';
  print('Fetching articles from: $url');
  
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final body = response.body;
      List<Map<String, dynamic>> articles = [];

      try {
        var rssFeed = RssFeed.parse(body);
        print('RSS Feed parsed successfully. Items: ${rssFeed.items?.length}');
        
        for (var item in rssFeed.items ?? []) {
          print('Item: ${item.title}');
          print('  Link: ${item.link}');
          print('  Description: ${item.description?.substring(0, (item.description?.length ?? 0).clamp(0, 100))}...');
        }
      } catch (e) {
        print('RSS parse error: $e');
      }
    }
  } catch(e) {
    print('HTTP error: $e');
  }
}
