import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/chat_message.dart';
import '../../models/chat_session.dart';

class StreamResponseData {
  final String? sessionId;
  final String? token;
  final bool isDone;

  StreamResponseData({this.sessionId, this.token, this.isDone = false});
}

class ApiService {
  final http.Client _client = http.Client();

  Stream<StreamResponseData> sendChatMessageStream({
    required String baseUrl,
    required String message,
    String? sessionId,
    String? modelOverride,
  }) async* {
    final uri = Uri.parse('$baseUrl/api/chat/stream');
    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'sessionId': sessionId,
        'message': message,
        'modelOverride': modelOverride,
      });

    final response = await _client.send(request);

    if (response.statusCode != 200) {
      throw Exception('Failed to connect to API endpoint. Status Code: ${response.statusCode}');
    }

    final stream = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in stream) {
      if (line.isEmpty) continue;

      if (line.startsWith('data: ')) {
        final dataContent = line.substring(6).trim();

        if (dataContent == '[DONE]') {
          yield StreamResponseData(isDone: true);
          break;
        }

        if (dataContent.startsWith('[SESSION_META]')) {
          final metaJsonStr = dataContent.substring(14);
          try {
            final meta = jsonDecode(metaJsonStr);
            yield StreamResponseData(sessionId: meta['sessionId']);
          } catch (_) {}
          continue;
        }

        try {
          final parsed = jsonDecode(dataContent);
          if (parsed is Map && parsed.containsKey('token')) {
            yield StreamResponseData(token: parsed['token']);
          }
        } catch (_) {
          // Plain text fallback token
          yield StreamResponseData(token: dataContent);
        }
      }
    }
  }

  Future<List<ChatSession>> fetchSessions(String baseUrl) async {
    final response = await http.get(Uri.parse('$baseUrl/api/chat/sessions'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ChatSession.fromJson(json)).toList();
    }
    throw Exception('Failed to load chat sessions');
  }

  Future<List<ChatMessage>> fetchHistory(String baseUrl, String sessionId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/chat/history/$sessionId'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> messagesJson = data['messages'] ?? [];
      return messagesJson.map((json) => ChatMessage.fromJson(json)).toList();
    }
    throw Exception('Failed to load session history');
  }

  Future<ChatSession> createSession(String baseUrl, {String? title}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/chat/sessions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title}),
    );
    if (response.statusCode == 200) {
      return ChatSession.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create new session');
  }

  Future<void> deleteSession(String baseUrl, String sessionId) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/chat/sessions/$sessionId'));
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete session');
    }
  }

  Future<bool> checkHealth(String baseUrl) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/chat/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
