import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/database_helper.dart'; // Dodany import bazy
import 'dashboard_screen.dart';
import 'add_medication_screen.dart';
import 'profile_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final int _selectedIndex = 1;
  bool _isLoading = true;

  int takenCount = 0;
  int missedCount = 0;
  String effectiveness = "0%";

  // Domyślne, puste dane przed wyliczeniem
  List<Map<String, dynamic>> _weeklyData = [
    {'day': 'Pn', 'percent': 0.0},
    {'day': 'Wt', 'percent': 0.0},
    {'day': 'Śr', 'percent': 0.0},
    {'day': 'Cz', 'percent': 0.0},
    {'day': 'Pt', 'percent': 0.0},
    {'day': 'Sb', 'percent': 0.0},
    {'day': 'Nd', 'percent': 0.0},
  ];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) return;

      // 1. Pobieranie danych dla górnych kafelków (od Przemka z serwera)
      final response = await http.get(
        Uri.parse('https://pill4u.onrender.com/api/history/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        takenCount = data['taken'] ?? 0;
        missedCount = data['missed'] ?? 0;
        effectiveness = data['effectiveness'] ?? "0%";
      }

      // 2. WYLICZANIE DYNAMICZNEGO WYKRESU TYGODNIOWEGO (z bazy lokalnej)
      final allHistory = await DatabaseHelper.instance.getAllHistory();

      // Przygotowujemy liczniki na każdy dzień obecnego tygodnia (1 = Poniedziałek, 7 = Niedziela)
      Map<int, int> takenPerDay = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
      Map<int, int> missedPerDay = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};

      final now = DateTime.now();
      // Obliczamy datę poniedziałku obecnego tygodnia
      final currentMonday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

      for (var h in allHistory) {
        final date = DateTime.tryParse(h['taken_at'] ?? '');
        // Sprawdzamy czy dany wpis należy do TEGO tygodnia
        if (date != null && (date.isAfter(currentMonday) || date.isAtSameMomentAs(currentMonday))) {
          final weekday = date.weekday;
          if (h['status'] == 'TAKEN') takenPerDay[weekday] = takenPerDay[weekday]! + 1;
          if (h['status'] == 'MISSED') missedPerDay[weekday] = missedPerDay[weekday]! + 1;
        }
      }

      List<Map<String, dynamic>> calculatedWeeklyData = [];
      final daysNames = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'Sb', 'Nd'];

      for (int i = 1; i <= 7; i++) {
        final t = takenPerDay[i]!;
        final m = missedPerDay[i]!;
        final total = t + m;
        // Obliczamy procent wziętych do wszystkich w danym dniu
        double percent = total > 0 ? (t / total) : 0.0;

        calculatedWeeklyData.add({
          'day': daysNames[i - 1],
          'percent': percent,
        });
      }

      if (mounted) {
        setState(() {
          _weeklyData = calculatedWeeklyData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 24.0),
              child: Text(
                'Twoje statystyki',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.green.withValues(alpha: 0.15) : const Color(0xFFE9FBF0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF34C759), size: 28),
                          const SizedBox(height: 12),
                          const Text('Wzięte', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('$takenCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.red.withValues(alpha: 0.15) : const Color(0xFFFCE8E8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.cancel, color: Color(0xFFFF3B30), size: 28),
                          const SizedBox(height: 12),
                          const Text('Pominięte', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('$missedCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF007AFF).withValues(alpha: 0.15) : const Color(0xFF007AFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Skuteczność', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(effectiveness, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFF007AFF))),
                      ],
                    ),
                    const Icon(Icons.show_chart, color: Color(0xFF007AFF), size: 40),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Aktywność w tym tygodniu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _weeklyData.map((data) {
                  final double percent = data['percent'];
                  return Column(
                    children: [
                      Container(
                        height: 120,
                        width: 24,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: percent,
                          child: Container(
                            decoration: BoxDecoration(
                              color: percent == 1.0 ? const Color(0xFF34C759) : const Color(0xFF007AFF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        data['day'],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
        ),
        child: BottomNavigationBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF007AFF),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          onTap: _onItemTapped,
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