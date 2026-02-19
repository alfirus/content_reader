import 'package:http/http.dart' as http;
import 'package:webfeed_plus/webfeed_plus.dart';

void main() async {
  final url = 'https://www.lowyat.net/feed/';
  print('Fetching: $url');
  
  try {
    final response = await http.get(Uri.parse(url));
    print('Status: ${response.statusCode}');
    print('Body length: ${response.body.length}');
    print('First 500 chars: ${response.body.substring(0, 500)}');
    
    // Try parsing RSS
    try {
      var feed = RssFeed.parse(response.body);
      print('RSS Title: ${feed.title}');
      print('RSS Items: ${feed.items?.length}');
      if (feed.items?.isNotEmpty == true) {
        print('First item: ${feed.items!.first.title}');
        print('First item link: ${feed.items!.first.link}');
      }
    } catch(e) {
      print('RSS Parse error: $e');
      
      // Try Atom
      try {
        var atom = AtomFeed.parse(response.body);
        print('Atom Title: ${atom.title}');
        print('Atom Items: ${atom.items?.length}');
      } catch(e2) {
        print('Atom Parse error: $e2');
      }
    }
  } catch(e) {
    print('HTTP Error: $e');
  }
}
