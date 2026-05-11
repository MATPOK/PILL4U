import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const Pill4UApp());
}

class Pill4UApp extends StatelessWidget {
  const Pill4UApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PILL4U',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, // Obsługa Dark Mode (wymóg z projektu)
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green, // Główny kolor medyczny
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}