import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dashboard_screen.dart';
import '../viewmodels/login_viewmodel.dart';
import 'main_layout_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginViewModel _viewModel = LoginViewModel();

  Future<void> _handleLogin() async {
    final result = await _viewModel.submit();
    if (result == null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
      );
    } else if (result == 'SUCCESS_REGISTER') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rejestracja udana! Możesz się zalogować.'), backgroundColor: Colors.green),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://pill4u.onrender.com/privacy');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie można otworzyć linku.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.3)
                                      : Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 5),
                                )
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: 80,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                            'Twój osobisty asystent lekowy',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant)
                        ),
                        const SizedBox(height: 48),

                        if (!_viewModel.isLogin) ...[
                          Text('Imię', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.primary)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _viewModel.nameController,
                            style: TextStyle(color: colorScheme.onSurface),
                            decoration: InputDecoration(
                              hintText: 'Wpisz swoje imię',
                              prefixIcon: Icon(Icons.person_outline, color: isDark ? Colors.grey : null),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        Text('Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.primary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _viewModel.emailController,
                          style: TextStyle(color: colorScheme.onSurface),
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: _viewModel.isLogin ? 'twoj@email.pl' : 'adres@email.com',
                            prefixIcon: Icon(Icons.email_outlined, color: isDark ? Colors.grey : null),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text('Hasło', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.primary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _viewModel.passwordController,
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: _viewModel.isLogin ? '••••••••' : 'Min. 8 znaków, litera i cyfra',
                            prefixIcon: Icon(Icons.lock_outline, color: isDark ? Colors.grey : null),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _viewModel.isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: isDark ? Colors.grey : Colors.grey.shade600,
                              ),
                              onPressed: _viewModel.togglePasswordVisibility,
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          obscureText: !_viewModel.isPasswordVisible,
                        ),
                        const SizedBox(height: 16),

                        if (!_viewModel.isLogin) ...[
                          Text('Potwierdź hasło', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.primary)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _viewModel.confirmPasswordController,
                            style: TextStyle(color: colorScheme.onSurface),
                            decoration: InputDecoration(
                              hintText: 'Powtórz hasło',
                              prefixIcon: Icon(Icons.lock_reset_outlined, color: isDark ? Colors.grey : null),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _viewModel.isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: isDark ? Colors.grey : Colors.grey.shade600,
                                ),
                                onPressed: _viewModel.toggleConfirmPasswordVisibility,
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            obscureText: !_viewModel.isConfirmPasswordVisible,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Checkbox(
                                value: _viewModel.acceptTerms,
                                activeColor: colorScheme.primary,
                                onChanged: (val) => _viewModel.setAcceptTerms(val ?? false),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: _launchPrivacyPolicy,
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      'Akceptuję politykę prywatności oraz regulamin',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        ElevatedButton(
                          onPressed: _viewModel.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007AFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _viewModel.isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(_viewModel.isLogin ? 'Zaloguj się' : 'Zarejestruj się', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _viewModel.toggleMode,
                          child: Text(
                            _viewModel.isLogin ? 'Nie masz konta? Zarejestruj się' : 'Masz już konto? Zaloguj się',
                            style: const TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.security, size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text('Twoje dane są bezpieczne i zaszyfrowane', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
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
