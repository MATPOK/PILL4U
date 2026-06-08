import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../helpers/notification_service.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final List<String> _days = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'Sb', 'Nd'];
  final Set<String> _selectedDays = {};
  bool isLoading = false;

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // POTĘŻNE OKNO DO WYŚWIETLANIA BŁĘDÓW KRYTYCZNYCH
  void _showCrashDialog(String error, String stackTrace) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('BŁĄD KRYTYCZNY', style: TextStyle(color: Colors.red)),
        content: SingleChildScrollView(
          child: Text('Treść błędu:\n$error\n\nŚcieżka:\n$stackTrace'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zrozumiałem'),
          )
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final dosage = _dosageController.text.trim();

    if (name.length < 2) {
      _showError('Nazwa leku musi mieć co najmniej 2 znaki!');
      return;
    }

    if (!RegExp(r'\d').hasMatch(dosage)) {
      _showError('Dawka musi zawierać konkretną wartość liczbową (np. 1 tabletka, 100mg)!');
      return;
    }

    if (_selectedDays.isEmpty) {
      _showError('Wybierz przynajmniej jeden dzień w tygodniu!');
      return;
    }

    setState(() { isLoading = true; });

    try {
      print('LOG: Rozpoczynam zapis leku...');
      final String timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
      final List<String> orderedSelectedDays = _days.where((d) => _selectedDays.contains(d)).toList();

      final Map<String, int> dayMapper = {'Pn': 1, 'Wt': 2, 'Śr': 3, 'Cz': 4, 'Pt': 5, 'Sb': 6, 'Nd': 7};
      final List<int> daysAsInts = orderedSelectedDays.map((d) => dayMapper[d]!).toList();
      final int baseNotificationId = DateTime.now().millisecondsSinceEpoch % 10000;

      print('LOG: Próbuję ustawić powiadomienie...');
      try {
        await NotificationService().scheduleMedicationNotification(
          id: baseNotificationId,
          title: 'Czas na lek: $name!',
          body: 'Przypomnienie o wzięciu dawki: $dosage',
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
          daysOfWeek: daysAsInts,
        );
        print('LOG: Powiadomienie ustawione SUKCES.');
      } catch (notifyError, notifyStack) {
        print('LOG BŁĄD POWIADOMIENIA: $notifyError');
        print('LOG STACK POWIADOMIENIA: $notifyStack');
      }

      print('LOG: Próbuję zapisać do bazy SQLite...');
      for (String day in orderedSelectedDays) {
        print('LOG: Zapisuję dzień: $day');
        await DatabaseHelper.instance.insertSingleMedication({
          'name': name,
          'dosage': dosage,
          'time': timeStr,
          'days': day,
        });
      }
      print('LOG: Zapis do SQLite SUKCES.');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lek zapisany!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);

    } catch (error, stackTrace) {
      print('LOG GŁÓWNY BŁĄD: $error');
      print('LOG GŁÓWNY STACKTRACE: $stackTrace');

      // Zamiast małego paska, wywali Ci pełne okno z informacją co się wyjebało
      _showCrashDialog(error.toString(), stackTrace.toString());

    } finally {
      if (mounted) {
        setState(() { isLoading = false; });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Dodaj lek', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nazwa leku', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'np. Witamina C',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Dawka', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _dosageController,
                decoration: InputDecoration(
                  hintText: 'np. 1 tabletka, 100mg',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Godzina', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectTime(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.access_time, color: Color(0xFF007AFF)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Dni tygodnia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _days.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                      });
                    },
                    selectedColor: isDark ? Colors.green.withValues(alpha: 0.3) : const Color(0xFFE9FBF0),
                    checkmarkColor: const Color(0xFF34C759),
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF34C759) : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Zapisz lek', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}