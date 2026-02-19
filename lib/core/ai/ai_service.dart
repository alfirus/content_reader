import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/article.dart';
import '../../data/datasources/database_helper.dart';

class AiService {
  static final AiService instance = AiService._();
  AiService._();

  /// Summarize article using OpenClaw via local server
  Future<String?> summarize(Article article) async {
    final settings = await _getSettings();
    
    if (!settings['aiSummarizationEnabled']) return null;
    if (!settings['openClawEnabled']) return null;
    if (article.link.isEmpty) return null;

    // Use the local server endpoint
    final serverUrl = 'http://localhost:3000/v1/chat/completions';
    
    // Build content from article
    String content = article.content;
    if (content.isEmpty) {
      content = article.summary;
    }
    if (content.isEmpty) {
      return null;
    }
    
    // Truncate if too long
    if (content.length > 4000) {
      content = content.substring(0, 4000);
    }

    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'local',
          'messages': [
            {'role': 'user', 'content': 'Summarize in 2-3 sentences:\n\nTitle: ${article.title}\n\n$content'}
          ]
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices']?[0]?['message']?['content'];
      } else {
        print('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Summarization error: $e');
    }
    
    return null;
  }

  /// Get settings
  Future<Map<String, dynamic>> _getSettings() async {
    final db = DatabaseHelper.instance;
    return {
      'aiSummarizationEnabled': await db.getSetting('aiSummarization') == 'true',
      'openClawEnabled': await db.getSetting('openClawEnabled') == 'true',
    };
  }
}
