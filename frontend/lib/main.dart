import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'helpers/notification_service.dart';
import 'helpers/settings_controller.dart'; // Dodany import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().init();
  await SettingsController().loadSettings(); // Wczytywanie ustawień z pamięci

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  runApp(MyApp(isLoggedIn: token != null));
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    NotificationService().requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder nasłuchuje zmian i odświeża CAŁĄ aplikację w czasie rzeczywistym
    return AnimatedBuilder(
      animation: SettingsController(),
      builder: (context, child) {
        return MaterialApp(
          title: 'PILL4U',
          debugShowCheckedModeBanner: false,

          // Konfiguracja trybu ciemnego
          theme: ThemeData.light(useMaterial3: true).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007AFF), brightness: Brightness.light),
          ),
          darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007AFF), brightness: Brightness.dark),
          ),
          themeMode: SettingsController().themeMode, // Decyduje czy ciemny, jasny czy systemowy

          // Skalowanie czcionki dla seniorów na CAŁĄ aplikację
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(SettingsController().textScale),
              ),
              child: child!,
            );
          },

          home: widget.isLoggedIn ? const DashboardScreen() : const LoginScreen(),
        );
      },
    );
  }
}