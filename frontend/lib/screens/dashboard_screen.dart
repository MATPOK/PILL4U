import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/database_helper.dart';
import 'add_medication_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _refreshTimer;
  List<dynamic> medications = [];
  final Set<int> _takenMedIds = {};
  final Set<int> _skippedMedIds = {};
  bool isLoading = true;
  int _selectedIndex = 0;
  String userName = "";

  @override
  void initState() {
    super.initState();
    _fetchData();

    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        _fetchData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _getFullWeekday(int weekday) {
    const days = ['', 'Poniedziałek', 'Wtorek', 'Środa', 'Czwartek', 'Piątek', 'Sobota', 'Niedziela'];
    return days[weekday];
  }

  String _getPolishMonth(int month) {
    const months = ['', 'Stycznia', 'Lutego', 'Marca', 'Kwietnia', 'Maja', 'Czerwca', 'Lipca', 'Sierpnia', 'Września', 'Października', 'Listopada', 'Grudnia'];
    return months[month];
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final localName = prefs.getString('user_name') ?? "";

    final localMeds = await DatabaseHelper.instance.getMedications();
    final todayHistory = await DatabaseHelper.instance.getTodayHistory();

    final now = DateTime.now();
    const apiDays = ['', 'Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'Sb', 'Nd'];
    final todayApiStr = apiDays[now.weekday];

    if (mounted) {
      setState(() {
        userName = localName;
        medications = localMeds.where((m) {
          final medDay = (m['days'] ?? '').toString().trim();
          return medDay == todayApiStr;
        }).toList();

        _takenMedIds.clear();
        _skippedMedIds.clear();
        for (var h in todayHistory) {
          if (h['status'] == 'TAKEN') _takenMedIds.add(h['medication_id'] as int);
          if (h['status'] == 'MISSED') _skippedMedIds.add(h['medication_id'] as int);
        }

        isLoading = false;
      });
    }
  }

  Future<void> _fetchData() async {
    await _loadLocalData();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) return;

      final userResponse = await http.get(
        Uri.parse('https://pill4u.onrender.com/api/user/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        final fetchedName = userData['name'] ?? "Użytkowniku";
        await prefs.setString('user_name', fetchedName);
        if (mounted) setState(() { userName = fetchedName; });
      }

      final dbMeds = await DatabaseHelper.instance.getMedications();
      final unsyncedMeds = dbMeds.where((m) => m['api_id'] == null).toList();
      for (var med in unsyncedMeds) {
        try {
          final response = await http.post(
            Uri.parse('https://pill4u.onrender.com/api/medications'),
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
            body: jsonEncode({'name': med['name'], 'dosage': med['dosage'], 'time': med['time'], 'days': med['days']}),
          );
          if (response.statusCode == 201 || response.statusCode == 200) {
            try {
              final responseData = jsonDecode(response.body);
              if (responseData['id'] != null && med['id'] != null) {
                await DatabaseHelper.instance.updateApiId(med['id'], responseData['id']);
              }
            } catch (_) {
              await DatabaseHelper.instance.updateApiId(med['id'], -1);
            }
          }
        } catch (e) { break; }
      }

      final unsyncedHistory = await DatabaseHelper.instance.getUnsyncedHistory();
      for (var item in unsyncedHistory) {
        try {
          final response = await http.post(
            Uri.parse('https://pill4u.onrender.com/api/history'),
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
            body: jsonEncode({'medicationId': item['medication_id'], 'medicationName': item['medication_name'], 'status': item['status'], 'takenAt': item['taken_at']}),
          );

          if (response.statusCode == 201 || response.statusCode == 200) {
            int newApiId = -1;
            try {
              final responseData = jsonDecode(response.body);
              if (responseData['id'] != null) newApiId = responseData['id'];
            } catch (_) {}

            await DatabaseHelper.instance.updateHistoryApiId(item['id'], newApiId);
          }
        } catch (e) { break; }
      }

      final medsResponse = await http.get(
        Uri.parse('https://pill4u.onrender.com/api/medications'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (medsResponse.statusCode == 200) {
        final allMeds = jsonDecode(medsResponse.body) as List;
        await DatabaseHelper.instance.insertMedications(allMeds);
      }

      final historyResponse = await http.get(
        Uri.parse('https://pill4u.onrender.com/api/history'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (historyResponse.statusCode == 200) {
        final allHistory = jsonDecode(historyResponse.body) as List;
        await DatabaseHelper.instance.syncHistoryFromServer(allHistory);
      }

      await _loadLocalData();

    } catch (e) {
      // Tryb offline
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _markAsTaken(int medId, String medName) async {
    if (_takenMedIds.contains(medId) || _skippedMedIds.contains(medId)) return;

    setState(() { _takenMedIds.add(medId); });
    await DatabaseHelper.instance.insertHistoryItem({
      'medication_id': medId,
      'medication_name': medName,
      'status': 'TAKEN',
      'taken_at': DateTime.now().toIso8601String(),
    });
    _fetchData();
  }

  Future<void> _markAsSkipped(int medId, String medName) async {
    if (_takenMedIds.contains(medId) || _skippedMedIds.contains(medId)) return;

    setState(() { _skippedMedIds.add(medId); });
    await DatabaseHelper.instance.insertHistoryItem({
      'medication_id': medId,
      'medication_name': medName,
      'status': 'MISSED',
      'taken_at': DateTime.now().toIso8601String(),
    });
    _fetchData();
  }

  // --- POPRAWKA: Cofanie używa dokładnie jednego medId ---
  Future<void> _undoMedicationStatus(int medId, String currentStatus) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cofnij akcję'),
        content: Text(currentStatus == 'TAKEN'
            ? 'Czy na pewno chcesz cofnąć informację o wzięciu tego leku?'
            : 'Czy na pewno chcesz cofnąć informację o pominięciu tego leku?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cofnij', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;
    setState(() { isLoading = true; });

    try {
      // Pobieramy wpis TYLKO dla tego jednego klikniętego leku
      final historyItems = await DatabaseHelper.instance.getTodayHistoryForMedId(medId);

      for (var item in historyItems) {
        final int localHistoryId = item['id'];
        final dynamic apiHistoryId = item['api_id'];

        if (apiHistoryId != null && apiHistoryId != -1) {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('jwt_token');
          if (token != null) {
            try {
              await http.delete(
                Uri.parse('https://pill4u.onrender.com/api/history/$apiHistoryId'),
                headers: {'Authorization': 'Bearer $token'},
              );
            } catch (e) { debugPrint('Błąd usuwania historii z API: $e'); }
          }
        }

        // TARCZA: Oznaczamy w bazie jako usunięte
        await DatabaseHelper.instance.softDeleteHistoryItem(localHistoryId);
      }

      setState(() {
        _takenMedIds.remove(medId);
        _skippedMedIds.remove(medId);
      });

      await _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Błąd podczas cofania akcji.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { isLoading = false; });
    }
  }

  Future<void> _deleteMedication(String name, String dosage, String time) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń lek'),
        content: Text('Czy na pewno chcesz usunąć lek "$name" zaplanowany na $time? Ta operacja skasuje go ze wszystkich dni.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usuń', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() { isLoading = true; });

    try {
      // Usuwamy wszystkie leki zgrupowane po tej samej nazwie, dawce i czasie
      final medsToDelete = await DatabaseHelper.instance.getMedicationGroup(name, dosage, time);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token != null) {
        for (var med in medsToDelete) {
          if (med['api_id'] != null && med['api_id'] != -1) {
            try {
              await http.delete(
                Uri.parse('https://pill4u.onrender.com/api/medications/${med['api_id']}'),
                headers: {'Authorization': 'Bearer $token'},
              );
            } catch (e) {
              debugPrint('Błąd usuwania z API: $e');
            }
          }
        }
      }

      await DatabaseHelper.instance.deleteMedicationGroup(name, dosage, time);
      await _fetchData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lek "$name" ($time) został usunięty.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wystąpił błąd podczas usuwania.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString = '${_getFullWeekday(now.weekday)}, ${now.day} ${_getPolishMonth(now.month)}';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Witaj${userName.isNotEmpty ? ", $userName" : ""}!',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateString,
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Twój harmonogram na dziś:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  const Tooltip(
                    message: 'Przytrzymaj lek, aby go usunąć',
                    triggerMode: TooltipTriggerMode.tap,
                    child: Icon(Icons.info_outline, color: Colors.grey, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : medications.isEmpty
                  ? const Center(child: Text('Brak leków na dziś.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                itemCount: medications.length,
                itemBuilder: (context, index) {
                  final med = medications[index];
                  final int medId = med['api_id'] ?? med['id'] ?? index;
                  final String medName = med['name'] ?? 'Lek';
                  final String medDosage = med['dosage'] ?? '';
                  final String timeStr = med['time'] ?? '00:00';

                  final bool isTaken = _takenMedIds.contains(medId);
                  final bool isSkipped = _skippedMedIds.contains(medId);

                  final timeParts = timeStr.split(':');
                  final medHour = int.tryParse(timeParts[0]) ?? 0;
                  final medMinute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;

                  final nowInMinutes = now.hour * 60 + now.minute;
                  final medInMinutes = medHour * 60 + medMinute;

                  final bool isPending = !isTaken && !isSkipped && (nowInMinutes < medInMinutes);

                  final Color cardBgColor = isTaken
                      ? (isDark ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFE9FBF0))
                      : isSkipped
                      ? (isDark ? Colors.red.withValues(alpha: 0.2) : const Color(0xFFFCE8E8))
                      : theme.cardColor;

                  final Color iconBgColor = isTaken
                      ? const Color(0xFF34C759)
                      : isSkipped
                      ? const Color(0xFFFF3B30)
                      : (isDark ? Colors.blue.withValues(alpha: 0.2) : const Color(0xFFEBF4FF));

                  final Color iconColor = isTaken || isSkipped ? Colors.white : const Color(0xFF007AFF);

                  return InkWell(
                    onLongPress: () => _deleteMedication(medName, medDosage, timeStr),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                        boxShadow: [
                          if (!isTaken && !isSkipped && !isDark)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.medication, color: iconColor, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  medName,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Dawka: $medDosage • $timeStr',
                                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          if (isTaken)
                            InkWell(
                              onTap: () => _undoMedicationStatus(medId, 'TAKEN'),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: theme.colorScheme.onSurface, size: 20),
                                    const SizedBox(width: 4),
                                    Text('Wzięty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
                                  ],
                                ),
                              ),
                            )
                          else if (isSkipped)
                            InkWell(
                              onTap: () => _undoMedicationStatus(medId, 'MISSED'),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.cancel, color: theme.colorScheme.onSurface, size: 20),
                                    const SizedBox(width: 4),
                                    Text('Pominięty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
                                  ],
                                ),
                              ),
                            )
                          else if (isPending)
                              const Text('Oczekiwanie', style: TextStyle(color: Colors.grey, fontSize: 14))
                            else
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _markAsTaken(medId, medName),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF007AFF),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Weź', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () => _markAsSkipped(medId, medName),
                                    style: TextButton.styleFrom(
                                      backgroundColor: const Color(0xFF007AFF),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Pomiń', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                        ],
                      ),
                    ),
                  );
                },
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
          onTap: (index) {
            if (index == 1) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
            } else if (index == 2) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AddMedicationScreen())).then((_) => _fetchData());
            } else if (index == 3) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            } else {
              setState(() => _selectedIndex = index);
            }
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