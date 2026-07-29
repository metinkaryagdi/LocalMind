import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final timeStr = DateFormat('HH:mm').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 8.0, top: 4.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF6366F1),
                child: const Icon(Icons.smart_toy_rounded, size: 18, color: Colors.white),
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF4F46E5) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.content.isEmpty && message.isStreaming) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SpinKitThreeBounce(
                          color: Color(0xFF818CF8),
                          size: 14.0,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "LocalMind is thinking...",
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      ],
                    )
                  ] else ...[
                    SelectableText(
                      message.content,
                      style: TextStyle(
                        color: Colors.grey.shade100,
                        fontSize: 15.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: isUser ? Colors.white70 : Colors.grey.shade400,
                          fontSize: 10.5,
                        ),
                      ),
                      if (message.isStreaming && message.content.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        const SizedBox(
                          width: 8,
                          height: 8,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF818CF8)),
                          ),
                        ),
                      ],
                      if (!isUser && !message.isStreaming && message.content.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: message.content));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Message copied to clipboard"),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Icon(
                            Icons.copy_rounded,
                            size: 13,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              margin: const EdgeInsets.only(left: 8.0, top: 4.0),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF3B82F6),
                child: Icon(Icons.person_rounded, size: 18, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
