import 'package:flutter/material.dart';
import '../viewmodels/add_medication_viewmodel.dart';
import 'main_layout_screen.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final AddMedicationViewModel _viewModel = AddMedicationViewModel();

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _viewModel.selectedTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _viewModel.selectTime(picked);
    }
  }

  Future<void> _submit() async {
    final result = await _viewModel.submit();
    if (result == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lek zapisany!'), backgroundColor: Colors.green),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
            (Route<dynamic> route) => false,
      );

    } else {
      if (!mounted) return;
      _showError(result);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
                    controller: _viewModel.nameController,
                    decoration: InputDecoration(
                      hintText: 'np. Witamina C',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Dawka', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _viewModel.dosageController,
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
                            '${_viewModel.selectedTime.hour.toString().padLeft(2, '0')}:${_viewModel.selectedTime.minute.toString().padLeft(2, '0')}',
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
                    children: _viewModel.days.map((day) {
                      final isSelected = _viewModel.selectedDays.contains(day);
                      return FilterChip(
                        label: Text(day),
                        selected: isSelected,
                        onSelected: (selected) => _viewModel.toggleDay(day),
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
                      onPressed: _viewModel.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _viewModel.isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Zapisz lek', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
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
