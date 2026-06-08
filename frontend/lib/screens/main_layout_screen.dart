import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'add_medication_screen.dart';
import 'profile_screen.dart';
import '../viewmodels/history_viewmodel.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _selectedIndex = 0;
  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  // Współdzielony ViewModel historii, żeby móc go odświeżyć przy wejściu na zakładkę.
  final HistoryViewModel _historyViewModel = HistoryViewModel();

  // Lista naszych ekranów. IndexedStack będzie je trzymał w pamięci.
  late final List<Widget> _screens = [
    const DashboardScreen(),
    HistoryScreen(viewModel: _historyViewModel),
    const AddMedicationScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkConnectivity();

    _subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      if (mounted) {
        setState(() {
          _isOffline = result.contains(ConnectivityResult.none);
        });
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isOffline = result.contains(ConnectivityResult.none);
      });
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _historyViewModel.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Po wejściu na zakładkę Historia (indeks 1) przeładowujemy dane z lokalnej bazy,
    // żeby pokazać zmiany zrobione w trybie offline (wzięcie/cofnięcie/dodanie leku).
    if (index == 1) {
      _historyViewModel.fetchStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _isOffline ? 32 : 0, // Płynnie rozwija się i chowa
              width: double.infinity,
              color: Colors.orangeAccent,
              child: const SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Brak internetu. Pracujesz w trybie offline',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: _screens,
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