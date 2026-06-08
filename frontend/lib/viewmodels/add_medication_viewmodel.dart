import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../helpers/notification_service.dart';
import '../models/medication.dart';

class AddMedicationViewModel extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  TimeOfDay selectedTime = TimeOfDay.now();

  final List<String> days = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'Sb', 'Nd'];
  final Set<String> selectedDays = {};
  bool isLoading = false;

  void selectTime(TimeOfDay picked) {
    selectedTime = picked;
    notifyListeners();
  }

  void toggleDay(String day) {
    if (selectedDays.contains(day)) {
      selectedDays.remove(day);
    } else {
      selectedDays.add(day);
    }
    notifyListeners();
  }

  Future<String?> submit() async {
    final name = nameController.text.trim();
    final dosage = dosageController.text.trim();

    if (name.length < 2) {
      return 'Nazwa leku musi mieć co najmniej 2 znaki!';
    }

    if (!RegExp(r'\d').hasMatch(dosage)) {
      return 'Dawka musi zawierać konkretną wartość liczbową (np. 1 tabletka, 100mg)!';
    }

    if (selectedDays.isEmpty) {
      return 'Wybierz przynajmniej jeden dzień w tygodniu!';
    }

    isLoading = true;
    notifyListeners();

    try {
      final String timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      final List<String> orderedSelectedDays = days.where((d) => selectedDays.contains(d)).toList();

      final Map<String, int> dayMapper = {'Pn': 1, 'Wt': 2, 'Śr': 3, 'Cz': 4, 'Pt': 5, 'Sb': 6, 'Nd': 7};
      final List<int> daysAsInts = orderedSelectedDays.map((d) => dayMapper[d]!).toList();
      final int baseNotificationId = DateTime.now().millisecondsSinceEpoch % 10000;

      try {
        await NotificationService().scheduleMedicationNotification(
          id: baseNotificationId,
          title: 'Czas na lek: $name!',
          body: 'Przypomnienie o wzięciu dawki: $dosage',
          hour: selectedTime.hour,
          minute: selectedTime.minute,
          daysOfWeek: daysAsInts,
        );
      } catch (e) {
        debugPrint('Błąd powiadomienia: $e');
      }

      for (String day in orderedSelectedDays) {
        await DatabaseHelper.instance.insertSingleMedication(Medication(
          name: name,
          dosage: dosage,
          time: timeStr,
          days: day,
        ));
      }

      return null; // Success
    } catch (e) {
      return e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    super.dispose();
  }
}
