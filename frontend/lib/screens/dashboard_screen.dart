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
        setState(() {});
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
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        final fetchedName = userData['name'] ?? "Użytkowniku";

        await prefs.setString('user_name', fetchedName);

        if (mounted) {
          setState(() {
            userName = fetchedName;
          });
        }
      }

      final dbMeds = await DatabaseHelper.instance.getMedications();
      final unsyncedMeds = dbMeds.where((m) => m['api_id'] == null).toList();

      for (var med in unsyncedMeds) {
        try {
          final response = await http.post(
            Uri.parse('https://pill4u.onrender.com/api/medications'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'name': med['name'],
              'dosage': med['dosage'],
              'time': med['time'],
              'days': med['days'],
            }),
          );

          if (response.statusCode == 201 || response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            final int? newApiId = responseData['id'];
            if (newApiId != null && med['id'] != null) {
              await DatabaseHelper.instance.updateApiId(med['id'], newApiId);
            }
          }
        } catch (e) {
          break;
        }
      }

      final medsResponse = await http.get(
        Uri.parse('https://pill4u.onrender.com/api/medications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (medsResponse.statusCode == 200) {
        final allMeds = jsonDecode(medsResponse.body) as List;
        await DatabaseHelper.instance.insertMedications(allMeds);
        await _loadLocalData();
      }
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _markAsTaken(int medId) {
    setState(() {
      _takenMedIds.add(medId);
      _skippedMedIds.remove(medId);
    });
  }

  void _markAsSkipped(int medId) {
    setState(() {
      _skippedMedIds.add(medId);
      _takenMedIds.remove(medId);
    });
  }

  void _resetStatus(int medId) {
    setState(() {
      _takenMedIds.remove(medId);
      _skippedMedIds.remove(medId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString = '${_getFullWeekday(now.weekday)}, ${now.day} ${_getPolishMonth(now.month)}';

    // Dynamiczny motyw
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 24.0),
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
              child: Text(
                'Twój harmonogram na dziś:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
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

                  final bool isTaken = _takenMedIds.contains(medId);
                  final bool isSkipped = _skippedMedIds.contains(medId);

                  final timeStr = med['time'] ?? '00:00';
                  final timeParts = timeStr.split(':');
                  final medHour = int.tryParse(timeParts[0]) ?? 0;
                  final medMinute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;

                  final nowInMinutes = now.hour * 60 + now.minute;
                  final medInMinutes = medHour * 60 + medMinute;

                  final bool isPending = !isTaken && !isSkipped && (nowInMinutes < medInMinutes);

                  // Kolory kart dostosowane do trybu nocnego
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

                  return Container(
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
                                med['name'] ?? 'Lek',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Dawka: ${med['dosage']} • $timeStr',
                                style: const TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        if (isTaken)
                          InkWell(
                            onTap: () => _resetStatus(medId),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: theme.colorScheme.onSurface, size: 20),
                                const SizedBox(width: 4),
                                Text('Wzięty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
                              ],
                            ),
                          )
                        else if (isSkipped)
                          InkWell(
                            onTap: () => _resetStatus(medId),
                            child: Row(
                              children: [
                                Icon(Icons.cancel, color: theme.colorScheme.onSurface, size: 20),
                                const SizedBox(width: 4),
                                Text('Pominięty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
                              ],
                            ),
                          )
                        else if (isPending)
                            const Text('Oczekiwanie', style: TextStyle(color: Colors.grey, fontSize: 14))
                          else
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () => _markAsTaken(medId),
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
                                  onPressed: () => _markAsSkipped(medId),
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
              ).then((_) {
                _fetchData();
              });
            } else if (index == 3) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
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