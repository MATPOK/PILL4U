import 'dart:convert';
import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../services/api_service.dart';
import '../models/history_entry.dart';

class HistoryViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool isLoading = true;
  int takenCount = 0;
  int missedCount = 0;
  String effectiveness = "0%";
  DateTime selectedDate = DateTime.now();
  List<HistoryEntry> dailyHistory = [];
  String? errorMessage;

  List<Map<String, dynamic>> weeklyData = [
    {'day': 'Pn', 'percent': 0.0},
    {'day': 'Wt', 'percent': 0.0},
    {'day': 'Śr', 'percent': 0.0},
    {'day': 'Cz', 'percent': 0.0},
    {'day': 'Pt', 'percent': 0.0},
    {'day': 'Sb', 'percent': 0.0},
    {'day': 'Nd', 'percent': 0.0},
  ];

  HistoryViewModel() {
    fetchStats();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchStats() async {
    isLoading = true;
    notifyListeners();

    try {
      final allHistory =
      await DatabaseHelper.instance.getAllHistory();

      takenCount = allHistory
          .where((h) => h.status == 'TAKEN')
          .length;

      missedCount = allHistory
          .where((h) => h.status == 'MISSED')
          .length;

      final total = takenCount + missedCount;

      effectiveness = total > 0
          ? "${((takenCount / total) * 100).round()}%"
          : "0%";

      errorMessage = null;


      Map<int, int> takenPerDay = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
      Map<int, int> missedPerDay = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};

      final now = DateTime.now();
      final currentMonday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

      for (var h in allHistory) {
        final date = DateTime.tryParse(h.takenAt);
        if (date != null && (date.isAfter(currentMonday) || date.isAtSameMomentAs(currentMonday))) {
          final weekday = date.weekday;
          if (h.status == 'TAKEN') takenPerDay[weekday] = takenPerDay[weekday]! + 1;
          if (h.status == 'MISSED') missedPerDay[weekday] = missedPerDay[weekday]! + 1;
        }
      }

      List<Map<String, dynamic>> calculatedWeeklyData = [];
      final daysNames = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'Sb', 'Nd'];

      for (int i = 1; i <= 7; i++) {
        final t = takenPerDay[i]!;
        final m = missedPerDay[i]!;
        final total = t + m;
        double percent = total > 0 ? (t / total) : 0.0;

        calculatedWeeklyData.add({
          'day': daysNames[i - 1],
          'percent': percent,
        });
      }

      weeklyData = calculatedWeeklyData;
      await fetchDailyHistory();
    } catch (e) {
      errorMessage = "Błąd połączenia. Statystyki mogą być nieaktualne.";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDailyHistory() async {
    final dateStr = selectedDate.toIso8601String().substring(0, 10);
    dailyHistory = await DatabaseHelper.instance.getHistoryForDate(dateStr);
    notifyListeners();
  }

  void selectDate(DateTime picked) {
    if (picked != selectedDate) {
      selectedDate = picked;
      fetchDailyHistory();
    }
  }
}