import 'package:flutter/material.dart';
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

  final List<Map<String, dynamic>> _weeklyData = [
    {'day': 'Pn', 'percent': 1.0},
    {'day': 'Wt', 'percent': 0.8},
    {'day': 'Śr', 'percent': 0.5},
    {'day': 'Cz', 'percent': 1.0},
    {'day': 'Pt', 'percent': 0.9},
    {'day': 'Sb', 'percent': 0.0},
    {'day': 'Nd', 'percent': 0.7},
  ];

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
      body: SafeArea(
        child: Column(
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
                        children: const [
                          Icon(Icons.check_circle, color: Color(0xFF34C759), size: 28),
                          SizedBox(height: 12),
                          Text('Wzięte', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          SizedBox(height: 4),
                          Text('42', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
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
                        children: const [
                          Icon(Icons.cancel, color: Color(0xFFFF3B30), size: 28),
                          SizedBox(height: 12),
                          Text('Pominięte', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          SizedBox(height: 4),
                          Text('5', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
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
                      children: const [
                        Text('Skuteczność', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        SizedBox(height: 4),
                        Text('89%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFF007AFF))),
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
                        style: TextStyle(
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