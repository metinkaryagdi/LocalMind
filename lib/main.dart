import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'providers/settings_provider.dart';
import 'ui/screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Catch any unhandled Flutter framework errors on physical devices
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  runApp(const LocalMindApp());
}

class LocalMindApp extends StatelessWidget {
  const LocalMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'LocalMind AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: const Color(0xFF0B0F17),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6366F1),
            secondary: Color(0xFF818CF8),
            surface: Color(0xFF0F172A),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0F172A),
            elevation: 0,
          ),
        ),
        home: const ChatScreen(),
      ),
    );
  }
}
