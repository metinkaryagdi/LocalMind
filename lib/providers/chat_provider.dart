import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/services/api_service.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';

enum ChatStatus { idle, connecting, streaming, error }

class ChatProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ScrollController scrollController = ScrollController();
  final _uuid = const Uuid();

  ChatStatus _status = ChatStatus.idle;
  List<ChatMessage> _messages = [];
  List<ChatSession> _sessions = [];
  String? _currentSessionId;
  String? _errorMessage;

  ChatStatus get status => _status;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<ChatSession> get sessions => List.unmodifiable(_sessions);
  String? get currentSessionId => _currentSessionId;
  String? get errorMessage => _errorMessage;
  bool get isStreaming => _status == ChatStatus.streaming;

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> fetchSessions(String baseUrl) async {
    try {
      _sessions = await _apiService.fetchSessions(baseUrl);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch sessions: $e';
    }
  }

  Future<void> selectSession(String sessionId, String baseUrl) async {
    _currentSessionId = sessionId;
    _status = ChatStatus.connecting;
    notifyListeners();

    try {
      _messages = await _apiService.fetchHistory(baseUrl, sessionId);
      _status = ChatStatus.idle;
      notifyListeners();
      scrollToBottom();
    } catch (e) {
      _status = ChatStatus.error;
      _errorMessage = 'Failed to load conversation history: $e';
      notifyListeners();
    }
  }

  void startNewSession() {
    _currentSessionId = null;
    _messages = [];
    _status = ChatStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> deleteSession(String sessionId, String baseUrl) async {
    try {
      await _apiService.deleteSession(baseUrl, sessionId);
      _sessions.removeWhere((s) => s.id == sessionId);
      if (_currentSessionId == sessionId) {
        startNewSession();
      } else {
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to delete session: $e';
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text, String baseUrl, String model) async {
    if (text.trim().isEmpty || isStreaming) return;

    final userMsgId = _uuid.v4();
    final assistantMsgId = _uuid.v4();

    // 1. Append User Message
    final userMessage = ChatMessage(
      id: userMsgId,
      sessionId: _currentSessionId ?? '',
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);

    // 2. Append Placeholder Assistant Message
    final assistantMessage = ChatMessage(
      id: assistantMsgId,
      sessionId: _currentSessionId ?? '',
      role: 'assistant',
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    _messages.add(assistantMessage);

    _status = ChatStatus.connecting;
    _errorMessage = null;
    notifyListeners();
    scrollToBottom();

    try {
      final stream = _apiService.sendChatMessageStream(
        baseUrl: baseUrl,
        message: text,
        sessionId: _currentSessionId,
        modelOverride: model,
      );

      _status = ChatStatus.streaming;
      notifyListeners();

      await for (final chunk in stream) {
        if (chunk.sessionId != null) {
          _currentSessionId = chunk.sessionId;
        }

        if (chunk.token != null) {
          final index = _messages.indexWhere((m) => m.id == assistantMsgId);
          if (index != -1) {
            final updatedContent = _messages[index].content + chunk.token!;
            _messages[index] = _messages[index].copyWith(content: updatedContent);
            notifyListeners();
            scrollToBottom();
          }
        }

        if (chunk.isDone) {
          break;
        }
      }

      // Mark streaming complete
      final index = _messages.indexWhere((m) => m.id == assistantMsgId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(isStreaming: false);
      }
      _status = ChatStatus.idle;
      fetchSessions(baseUrl); // Refresh session list
      notifyListeners();
    } catch (e) {
      _status = ChatStatus.error;
      _errorMessage = 'Streaming error: $e';
      final index = _messages.indexWhere((m) => m.id == assistantMsgId);
      if (index != -1 && _messages[index].content.isEmpty) {
        _messages[index] = _messages[index].copyWith(
          content: '⚠️ Failed to receive response from LocalMind server. Check connection.',
          isStreaming: false,
        );
      }
      notifyListeners();
    }
  }
}
