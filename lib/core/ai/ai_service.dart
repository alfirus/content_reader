import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/article.dart';
import '../../data/datasources/database_helper.dart';

class AiService {
  static final AiService instance = AiService._();
  String _serverUrl = 'http://localhost:3000/v1/chat/completions';
  
  AiService._();
  
  /// Initialize with saved server URL
  Future<void> initialize() async {
    final db = DatabaseHelper.instance;
    final savedUrl = await db.getSetting('openclaw_server_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _serverUrl = savedUrl;
    }
  }
  
  /// Set custom server URL
  Future<void> setServerUrl(String url) async {
    _serverUrl = url;
    final db = DatabaseHelper.instance;
    await db.setSetting('openclaw_server_url', url);
  }
  
  /// Get current server URL
  String get serverUrl => _serverUrl;

  /// Summarize article using OpenClaw via local server with retry logic
  Future<String?> summarize(Article article, {int retries = 2}) async {
    final settings = await _getSettings();
    
    if (!settings['aiSummarizationEnabled']) return null;
    if (!settings['openClawEnabled']) return null;
    if (article.link.isEmpty) return null;

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

    for (int i = 0; i <= retries; i++) {
      try {
        final response = await http.post(
          Uri.parse(_serverUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'model': 'local',
            'messages': [
              {'role': 'user', 'content': 'Summarize in 2-3 sentences:\n\nTitle: ${article.title}\n\n$content'}
            ],
            'max_tokens': 200, // Limit response length
          }),
        ).timeout(const Duration(seconds: 60)); // Increased timeout

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['choices']?[0]?['message']?['content'];
        } else {
          print('Server error: ${response.statusCode}');
        }
      } catch (e) {
        print('Summarization attempt ${i + 1} failed: $e');
        if (i == retries) {
          print('All retry attempts exhausted');
          return null;
        }
        // Exponential backoff
        await Future.delayed(Duration(seconds: 2 * (i + 1)));
      }
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
