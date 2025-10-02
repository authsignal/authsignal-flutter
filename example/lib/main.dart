import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const AuthsignalExampleApp());
}

class AuthsignalExampleApp extends StatelessWidget {
  const AuthsignalExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Authsignal Flutter Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

