import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'add_medication_screen.dart';
import 'login_screen.dart'; // Import potrzebny do powrotu po wylogowaniu

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final int _selectedIndex = 3; // Index 3 oznacza zakładkę "Profil"

  Future<void> _logout() async {
    // Czyszczenie tokena po wylogowaniu
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_name');

    if (!mounted) return;

    // pushAndRemoveUntil czyści CAŁĄ historię ekranów, żeby nie dało się wrócić do apki po wylogowaniu
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Ukrywa domyślną strzałkę "wstecz" (bo mamy dolny pasek)
        title: const Text(
          'Profil',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 28),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF007AFF),
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text('Wyloguj się', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3B30), // Czerwony kolor dla przycisku wylogowania
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF007AFF),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
              );
            } else if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
              );
            }
            // index == 3 to Profil, więc nic nie robimy, bo już tu jesteśmy
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today, size: 28), label: 'Dziś'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart, size: 28), label: 'Historia'),
            BottomNavigationBarItem(icon: Icon(Icons.add, size: 28), label: 'Dodaj'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 28), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}