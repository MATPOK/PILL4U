import 'dart:async';
import 'package:flutter/material.dart';
import '../viewmodels/dashboard_viewmodel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardViewModel _viewModel = DashboardViewModel();
  Timer? _uiRefreshTimer; // Lokalny timer do odświeżania "Oczekiwania"

  @override
  void initState() {
    super.initState();
    // Odświeżamy UI (tylko sam zegarek) co 5 sekund
    _uiRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiRefreshTimer?.cancel();
    _viewModel.dispose();
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

    try {
      await _viewModel.undoMedicationStatus(medId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Błąd podczas cofania akcji.'), backgroundColor: Colors.red),
        );
      }
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

    try {
      await _viewModel.deleteMedication(name, dosage, time);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString = '${_getFullWeekday(now.weekday)}, ${now.day} ${_getPolishMonth(now.month)}';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_viewModel.syncError != null)
                  MaterialBanner(
                    content: Text(_viewModel.syncError!),
                    leading: const Icon(Icons.error_outline, color: Colors.white),
                    backgroundColor: Colors.redAccent,
                    contentTextStyle: const TextStyle(color: Colors.white),
                    actions: [
                      TextButton(
                        onPressed: _viewModel.clearError,
                        child: const Text('OK', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Witaj${_viewModel.userName.isNotEmpty ? ", ${_viewModel.userName}" : ""}!',
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
                  child: _viewModel.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _viewModel.medications.isEmpty
                      ? const Center(child: Text('Brak leków na dziś.', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    itemCount: _viewModel.medications.length,
                    itemBuilder: (context, index) {
                      final med = _viewModel.medications[index];
                      // POPRAWKA: Pobieramy ZAWSZE lokalne ID jako nadrzędny klucz w UI, a API ID jako fallback.
                      // Dzięki temu w UI dwa duplikaty mają osobne tożsamości.
                      final int medId = med.id ?? med.apiId ?? index;

                      final String medName = med.name;
                      final String medDosage = med.dosage;
                      final String timeStr = med.time;

                      final bool isTaken = _viewModel.takenMedIds.contains(medId);
                      final bool isSkipped = _viewModel.skippedMedIds.contains(medId);

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
                                        onPressed: () => _viewModel.markAsTaken(medId, medName),
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
                                        onPressed: () => _viewModel.markAsSkipped(medId, medName),
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
        );
      },
    );
  }
}