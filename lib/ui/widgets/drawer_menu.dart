import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/settings_provider.dart';
import '../screens/settings_screen.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology_rounded, color: Color(0xFF6366F1), size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    "LocalMind History",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  chatProvider.startNewSession();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text("New Conversation", style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            Expanded(
              child: chatProvider.sessions.isEmpty
                  ? const Center(
                      child: Text("No saved conversations yet", style: TextStyle(color: Colors.white38)),
                    )
                  : ListView.builder(
                      itemCount: chatProvider.sessions.length,
                      itemBuilder: (context, index) {
                        final session = chatProvider.sessions[index];
                        final isSelected = session.id == chatProvider.currentSessionId;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 18,
                              color: isSelected ? const Color(0xFF818CF8) : Colors.white54,
                            ),
                            title: Text(
                              session.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.white38),
                              onPressed: () {
                                chatProvider.deleteSession(session.id, settingsProvider.apiUrl);
                              },
                            ),
                            onTap: () {
                              chatProvider.selectSession(session.id, settingsProvider.apiUrl);
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                    ),
            ),
            const Divider(color: Color(0xFF1E293B)),
            ListTile(
              leading: const Icon(Icons.settings_rounded, color: Colors.white70),
              title: const Text("Server Settings", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
