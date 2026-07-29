import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiUrlController;
  late TextEditingController _modelController;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _apiUrlController = TextEditingController(text: settings.apiUrl);
    _modelController = TextEditingController(text: settings.selectedModel);
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("LocalMind Server Settings", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "LAN Connection Configuration",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Enter the Local Area Network (LAN) IP address of your Server Machine hosting the .NET 9 Web API.",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiUrlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Server Base URL",
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: "http://192.168.1.50:5000",
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.dns_rounded, color: Color(0xFF818CF8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _modelController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Ollama Target Model",
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: "llama3.2:3b or phi3:mini",
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.memory_rounded, color: Color(0xFF818CF8)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      await settings.updateApiUrl(_apiUrlController.text);
                      await settings.updateModel(_modelController.text);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Server settings updated successfully")),
                        );
                      }
                    },
                    icon: const Icon(Icons.save_rounded, color: Colors.white),
                    label: const Text("Save Configuration", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    side: const BorderSide(color: Color(0xFF6366F1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    settings.checkConnection();
                  },
                  icon: settings.isCheckingConnection
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: const Text("Test Ping", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: settings.isConnected ? Colors.green.shade600 : Colors.red.shade600,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    settings.isConnected ? Icons.check_circle_rounded : Icons.error_rounded,
                    color: settings.isConnected ? Colors.greenAccent : Colors.redAccent,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.isConnected ? "Connected to LocalMind Server" : "Disconnected",
                          style: TextStyle(
                            color: settings.isConnected ? Colors.greenAccent : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          settings.isConnected
                              ? "Ollama AI service is reachable at ${settings.apiUrl}"
                              : "Could not reach server at ${settings.apiUrl}. Verify server IP & firewall rules.",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
