import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'add_medication_screen.dart';
import 'profile_screen.dart';
import '../viewmodels/history_viewmodel.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryViewModel _viewModel = HistoryViewModel();
  final int _selectedIndex = 1;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _viewModel.selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF007AFF),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _viewModel.selectDate(picked);
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

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                if (_viewModel.errorMessage != null)
                  MaterialBanner(
                    content: Text(_viewModel.errorMessage!),
                    leading: const Icon(Icons.error_outline, color: Colors.white),
                    backgroundColor: Colors.orangeAccent,
                    contentTextStyle: const TextStyle(color: Colors.white),
                    actions: [
                      TextButton(
                        onPressed: _viewModel.clearError,
                        child: const Text('OK', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                Expanded(
                  child: _viewModel.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
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
                              children: [
                                const Icon(Icons.check_circle, color: Color(0xFF34C759), size: 28),
                                const SizedBox(height: 12),
                                const Text('Wzięte', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('${_viewModel.takenCount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
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
                                Text('${_viewModel.missedCount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
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
                              Text(_viewModel.effectiveness, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFF007AFF))),
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
                      children: _viewModel.weeklyData.map((data) {
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
                  const SizedBox(height: 32),
                  Divider(color: Colors.grey.withValues(alpha: 0.2), thickness: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Zapisy z dnia: ${_viewModel.selectedDate.day.toString().padLeft(2, '0')}.${_viewModel.selectedDate.month.toString().padLeft(2, '0')}.${_viewModel.selectedDate.year}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_month, color: Color(0xFF007AFF), size: 28),
                          onPressed: () => _selectDate(context),
                          tooltip: 'Wybierz datę',
                        ),
                      ],
                    ),
                  ),

                  if (_viewModel.dailyHistory.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'Brak historii leków na ten dzień.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: _viewModel.dailyHistory.map((item) {
                          final bool isTaken = item.status == 'TAKEN';
                          final String timeStr = DateTime.tryParse(item.takenAt) != null
                              ? '${DateTime.parse(item.takenAt).toLocal().hour.toString().padLeft(2, '0')}:${DateTime.parse(item.takenAt).toLocal().minute.toString().padLeft(2, '0')}'
                              : '--:--';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: isTaken
                                  ? (isDark ? Colors.green.withValues(alpha: 0.15) : const Color(0xFFE9FBF0))
                                  : (isDark ? Colors.red.withValues(alpha: 0.15) : const Color(0xFFFCE8E8)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                    isTaken ? Icons.check_circle : Icons.cancel,
                                    color: isTaken ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                                    size: 24
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.medicationName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isTaken ? 'Wzięty o $timeStr' : 'Pominięty o $timeStr',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
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
      },
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}
