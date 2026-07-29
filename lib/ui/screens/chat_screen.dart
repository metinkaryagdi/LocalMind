import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/drawer_menu.dart';
import '../widgets/message_input.dart';
import 'settings_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final chat = Provider.of<ChatProvider>(context, listen: false);
      chat.fetchSessions(settings.apiUrl);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 1,
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: settingsProvider.isConnected ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "LocalMind AI",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  settingsProvider.selectedModel,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_rounded, color: Colors.white70),
            tooltip: "New Chat",
            onPressed: () => chatProvider.startNewSession(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white70),
            tooltip: "Server Settings",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      drawer: const DrawerMenu(),
      body: Column(
        children: [
          Expanded(
            child: chatProvider.messages.isEmpty
                ? _buildEmptyState(context, chatProvider, settingsProvider)
                : ListView.builder(
                    controller: chatProvider.scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: chatProvider.messages.length,
                    itemBuilder: (context, index) {
                      return ChatBubble(message: chatProvider.messages[index]);
                    },
                  ),
          ),
          if (chatProvider.errorMessage != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade900.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                chatProvider.errorMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          MessageInput(
            isStreaming: chatProvider.isStreaming,
            onSend: (text) {
              chatProvider.sendMessage(text, settingsProvider.apiUrl, settingsProvider.selectedModel);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ChatProvider chatProvider, SettingsProvider settingsProvider) {
    final samplePrompts = [
      "Explain Clean Architecture in C# with a brief example.",
      "Write a Flutter widget for SSE token streaming.",
      "Summarize the benefits of offline local SLM models.",
      "Help me debug an offline LAN network configuration."
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6366F1).withOpacity(0.15),
            ),
            child: const Icon(Icons.psychology_rounded, size: 64, color: Color(0xFF818CF8)),
          ),
          const SizedBox(height: 16),
          const Text(
            "Welcome to LocalMind",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Your private, offline AI assistant running locally on your network.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 32),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Suggested Prompts:",
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          ...samplePrompts.map((prompt) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () {
                    chatProvider.sendMessage(prompt, settingsProvider.apiUrl, settingsProvider.selectedModel);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF818CF8)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            prompt,
                            style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white38),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
