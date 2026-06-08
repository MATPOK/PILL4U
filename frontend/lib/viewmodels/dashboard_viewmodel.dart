import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/database_helper.dart';
import '../services/api_service.dart';
import '../models/medication.dart';
import '../models/history_entry.dart';

class DashboardViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  Timer? _refreshTimer;
  List<Medication> medications = [];
  final Set<int> _takenMedIds = {};
  final Set<int> _skippedMedIds = {};
  bool isLoading = true;
  String userName = "";
  String? syncError;

  Set<int> get takenMedIds => _takenMedIds;
  Set<int> get skippedMedIds => _skippedMedIds;

  DashboardViewModel() {
    fetchData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      fetchData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void clearError() {
    syncError = null;
    notifyListeners();
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('user_name') ?? "";

    final localMeds = await DatabaseHelper.instance.getMedications();
    final todayHistory = await DatabaseHelper.instance.getTodayHistory();

    final now = DateTime.now();
    const apiDays = ['', 'Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'Sb', 'Nd'];
    final todayApiStr = apiDays[now.weekday];

    medications = localMeds.where((m) {
      return m.days.trim() == todayApiStr;
    }).toList();

    _takenMedIds.clear();
    _skippedMedIds.clear();

    // Sprytnie sprawdzamy obydwa identyfikatory - z serwera i z telefonu
    for (var h in todayHistory) {
      int idToMark = h.medicationId;
      try {
        final matchedMed = localMeds.firstWhere((m) => m.apiId == h.medicationId);
        idToMark = matchedMed.id!;
      } catch (_) {}

      if (h.status == 'TAKEN') {
        _takenMedIds.add(h.medicationId);
        _takenMedIds.add(idToMark);
      }
      if (h.status == 'MISSED') {
        _skippedMedIds.add(h.medicationId);
        _skippedMedIds.add(idToMark);
      }
    }
    notifyListeners();
  }

  Future<void> fetchData() async {
    await _loadLocalData();

    try {
      final userResponse = await _apiService.getMe();
      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        userName = userData['name'] ?? "Użytkowniku";
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', userName);
      } else if (userResponse.statusCode >= 500) {
        syncError = "Błąd serwera (500). Nie udało się pobrać profilu.";
      }

      final dbMeds = await DatabaseHelper.instance.getMedications();
      final unsyncedMeds = dbMeds.where((m) => m.apiId == null).toList();
      for (var med in unsyncedMeds) {
        try {
          final response = await _apiService.postMedication(med);
          if (response.statusCode == 201 || response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            if (responseData['id'] != null && med.id != null) {
              await DatabaseHelper.instance.updateApiId(med.id!, responseData['id']);
            }
          } else {
            syncError = "Błąd serwera przy synchronizacji leku ${med.name}.";
          }
        } catch (e) {
          // Brak internetu sygnalizuje globalny pasek offline – nie dublujemy komunikatu.
          break;
        }
      }

      // Dosyłamy usunięcia leków zrobione w trybie offline.
      final medsPendingDelete = await DatabaseHelper.instance.getMedicationsPendingDelete();
      for (var med in medsPendingDelete) {
        if (med.apiId == null || med.apiId == -1) {
          await DatabaseHelper.instance.deleteMedicationById(med.id!);
          continue;
        }
        try {
          final response = await _apiService.deleteMedication(med.apiId!);
          // 404 = leku już nie ma na serwerze, więc też traktujemy jako sukces.
          if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 404) {
            await DatabaseHelper.instance.deleteMedicationById(med.id!);
          }
        } catch (e) {
          break; // wciąż offline – spróbujemy następnym razem
        }
      }

      final unsyncedHistory = await DatabaseHelper.instance.getUnsyncedHistory();
      for (var item in unsyncedHistory) {
        try {
          // Musimy przetłumaczyć nasze lokalne ID na API_ID dla Przemka
          final localMed = await DatabaseHelper.instance.getMedicationById(item.medicationId);
          if (localMed == null || localMed.apiId == null) continue; // Lek nie zdążył się zsynchronizować

          final apiHistoryItem = item.copyWith(medicationId: localMed.apiId);
          final response = await _apiService.postHistory(apiHistoryItem);
          if (response.statusCode == 201 || response.statusCode == 200) {
            int newApiId = -1;
            final responseData = jsonDecode(response.body);
            if (responseData['id'] != null) newApiId = responseData['id'];
            await DatabaseHelper.instance.updateHistoryApiId(item.id!, newApiId);
          } else {
            syncError = "Błąd serwera przy synchronizacji historii.";
          }
        } catch (e) {
          // Brak internetu sygnalizuje globalny pasek offline – nie dublujemy komunikatu.
          break;
        }
      }

      // Dosyłamy cofnięcia wzięć/pominięć (usunięcia historii) zrobione w trybie offline.
      final historyPendingDelete = await DatabaseHelper.instance.getHistoryPendingServerDelete();
      for (var item in historyPendingDelete) {
        try {
          final response = await _apiService.deleteHistory(item.apiId!);
          // 404 = wpisu już nie ma na serwerze, więc też traktujemy jako sukces.
          if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 404) {
            await DatabaseHelper.instance.deleteHistoryItemById(item.id!);
          }
        } catch (e) {
          break; // wciąż offline – spróbujemy następnym razem
        }
      }

      final medsResponse = await _apiService.getMedications();
      if (medsResponse.statusCode == 200) {
        final List<dynamic> allMedsJson = jsonDecode(medsResponse.body);
        final allMeds = allMedsJson.map((m) => Medication.fromJson(m)).toList();
        await DatabaseHelper.instance.insertMedications(allMeds);
      }

      final historyResponse = await _apiService.getHistory();
      if (historyResponse.statusCode == 200) {
        final List<dynamic> allHistoryJson = jsonDecode(historyResponse.body);
        final allHistory = allHistoryJson.map((h) => HistoryEntry.fromJson(h)).toList();
        await DatabaseHelper.instance.syncHistoryFromServer(allHistory);
      }

      await _loadLocalData();
    } catch (e) {
      // Tryb offline jest już pokazywany globalnym paskiem w MainLayoutScreen,
      // więc nie ustawiamy tu zduplikowanego banera o braku połączenia.
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsTaken(int medId, String medName) async {
    final med = medications.firstWhere((m) => m.id == medId || m.apiId == medId);

    if (_takenMedIds.contains(med.id) || _skippedMedIds.contains(med.id)) return;

    _takenMedIds.add(med.id!);
    if (med.apiId != null) _takenMedIds.add(med.apiId!);

    notifyListeners();
    await DatabaseHelper.instance.insertHistoryItem(HistoryEntry(
      medicationId: med.id!, // Zapisujemy jako lokalne, tłumacz pole wyżej
      medicationName: medName,
      status: 'TAKEN',
      takenAt: DateTime.now().toIso8601String(),
    ));
    await fetchData();
  }

  Future<void> markAsSkipped(int medId, String medName) async {
    final med = medications.firstWhere((m) => m.id == medId || m.apiId == medId);

    if (_takenMedIds.contains(med.id) || _skippedMedIds.contains(med.id)) return;

    _skippedMedIds.add(med.id!);
    if (med.apiId != null) _skippedMedIds.add(med.apiId!);

    notifyListeners();
    await DatabaseHelper.instance.insertHistoryItem(HistoryEntry(
      medicationId: med.id!,
      medicationName: medName,
      status: 'MISSED',
      takenAt: DateTime.now().toIso8601String(),
    ));
    await fetchData();
  }

  Future<void> undoMedicationStatus(int medId) async {
    isLoading = true;
    notifyListeners();

    try {
      final med = medications.firstWhere((m) => m.id == medId || m.apiId == medId);
      final historyItems = await DatabaseHelper.instance.getTodayHistoryForMedIds(med.id!, med.apiId);

      for (var item in historyItems) {
        if (item.apiId != null && item.apiId != -1) {
          // Wpis jest na serwerze – próbujemy usunąć go również tam.
          try {
            final response = await _apiService.deleteHistory(item.apiId!);
            if (response.statusCode == 200 || response.statusCode == 204) {
              await DatabaseHelper.instance.deleteHistoryItemById(item.id!);
            } else {
              syncError = "Serwer odrzucił żądanie usunięcia wpisu.";
              await DatabaseHelper.instance.softDeleteHistoryItem(item.id!);
            }
          } catch (e) {
            // Offline: chowamy wpis lokalnie i ponowimy usunięcie z serwera przy synchronizacji.
            await DatabaseHelper.instance.softDeleteHistoryItem(item.id!);
          }
        } else {
          // Wpis nigdy nie trafił na serwer – wystarczy ukryć go lokalnie.
          await DatabaseHelper.instance.softDeleteHistoryItem(item.id!);
        }
      }

      _takenMedIds.remove(med.id);
      if (med.apiId != null) _takenMedIds.remove(med.apiId);
      _skippedMedIds.remove(med.id);
      if (med.apiId != null) _skippedMedIds.remove(med.apiId);

      await fetchData();
    } catch (e) {
      syncError = "Wystąpił błąd krytyczny podczas cofania akcji.";
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMedication(String name, String dosage, String time) async {
    isLoading = true;
    notifyListeners();

    try {
      final medsToDelete = await DatabaseHelper.instance.getMedicationGroup(name, dosage, time);
      for (var med in medsToDelete) {
        if (med.apiId != null && med.apiId != -1) {
          // Lek jest na serwerze – próbujemy usunąć go również tam.
          try {
            final response = await _apiService.deleteMedication(med.apiId!);
            if (response.statusCode == 200 || response.statusCode == 204) {
              await DatabaseHelper.instance.deleteMedicationById(med.id!);
            } else {
              syncError = "Serwer odrzucił żądanie usunięcia leku.";
              await DatabaseHelper.instance.markMedicationPendingDelete(med.id!);
            }
          } catch (e) {
            // Offline: chowamy lek lokalnie i ponowimy usunięcie z serwera przy synchronizacji.
            await DatabaseHelper.instance.markMedicationPendingDelete(med.id!);
          }
        } else {
          // Lek nigdy nie trafił na serwer – usuwamy go lokalnie od razu.
          await DatabaseHelper.instance.deleteMedicationById(med.id!);
        }
      }

      await fetchData();
    } catch (e) {
      syncError = "Wystąpił błąd krytyczny podczas usuwania leku.";
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}