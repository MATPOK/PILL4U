import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'add_medication_screen.dart';
import 'login_screen.dart';
import '../helpers/settings_controller.dart';
import '../viewmodels/profile_viewmodel.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileViewModel _viewModel = ProfileViewModel();

  Future<void> _logout() async {
    await _viewModel.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        title: Text(
          'Profil',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: colorScheme.onSurface),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
            animation: SettingsController(),
            builder: (context, child) {
              final settings = SettingsController();
              final isSystemTheme = settings.themeMode == ThemeMode.system;
              final isDarkTheme = settings.themeMode == ThemeMode.dark;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: colorScheme.primary,
                        child: const Icon(Icons.person, size: 60, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 48),

                    Text('Wygląd aplikacji', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: const Text('Zgodnie z ustawieniami telefonu', style: TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: const Text('Aplikacja dostosuje się do motywu systemu'),
                      value: isSystemTheme,
                      activeColor: colorScheme.primary,
                      onChanged: (value) {
                        settings.updateThemeMode(value ? ThemeMode.system : ThemeMode.light);
                      },
                    ),

                    SwitchListTile(
                      title: const Text('Wymuś tryb ciemny', style: TextStyle(fontWeight: FontWeight.w500)),
                      value: isDarkTheme,
                      activeColor: colorScheme.primary,
                      onChanged: isSystemTheme ? null : (value) {
                        settings.updateThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                      },
                    ),

                    const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Divider()),

                    Text('Rozmiar tekstu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _FontButton(label: 'Mały', scale: 0.85, currentScale: settings.textScale),
                        _FontButton(label: 'Średni', scale: 1.0, currentScale: settings.textScale),
                        _FontButton(label: 'Duży', scale: 1.25, currentScale: settings.textScale),
                      ],
                    ),

                    const SizedBox(height: 64),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text('Wyloguj się', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF3B30),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
        ),
      ),
    );
  }
}

class _FontButton extends StatelessWidget {
  final String label;
  final double scale;
  final double currentScale;

  const _FontButton({required this.label, required this.scale, required this.currentScale});

  @override
  Widget build(BuildContext context) {
    final isSelected = currentScale == scale;
    final colorScheme = Theme.of(context).colorScheme;

    return ElevatedButton(
      onPressed: () => SettingsController().updateTextScale(scale),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? colorScheme.primary : colorScheme.surfaceVariant,
        foregroundColor: isSelected ? Colors.white : colorScheme.onSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
