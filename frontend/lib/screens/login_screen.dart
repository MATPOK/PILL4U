import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  bool acceptTerms = false;
  bool isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  Future<void> _submit() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');
    final nameRegex = RegExp(r'^[A-ZĄĆĘŁŃÓŚŹŻ][a-ząćęłńóśźż]+$');

    if (email.isEmpty || password.isEmpty) {
      _showError('Wypełnij email i hasło!');
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      _showError('Podaj poprawny format adresu email!');
      return;
    }

    if (!isLogin) {
      if (name.isEmpty) {
        _showError('Wypełnij pole Imię!');
        return;
      }
      if (!nameRegex.hasMatch(name)) {
        _showError('Imię musi zaczynać się z dużej litery i zawierać tylko litery!');
        return;
      }
      if (!passwordRegex.hasMatch(password)) {
        _showError('Hasło musi mieć min. 8 znaków, literę i cyfrę!');
        return;
      }
      if (password != _confirmPasswordController.text) {
        _showError('Podane hasła nie są identyczne!');
        return;
      }
      if (!acceptTerms) {
        _showError('Musisz zaakceptować regulamin!');
        return;
      }
    }

    setState(() { isLoading = true; });

    final String endpoint = isLogin ? 'login' : 'register';
    final Uri url = Uri.parse('https://pill4u.onrender.com/api/$endpoint');

    final Map<String, dynamic> requestBody = {
      'email': email,
      'password': password,
    };

    if (!isLogin) {
      requestBody['name'] = name;
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (isLogin) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', responseData['token']);

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rejestracja udana! Możesz się zalogować.'), backgroundColor: Colors.green),
          );
          setState(() {
            isLogin = true;
            _passwordController.clear();
            _confirmPasswordController.clear();
          });
        }
      } else {
        _showError(responseData['error'] ?? 'Nieprawidłowe dane');
      }
    } catch (error) {
      _showError('Błąd połączenia z serwerem.');
    } finally {
      if (mounted) {
        setState(() { isLoading = false; });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ✅ POPRAWKA: canLaunchUrl przed launchUrl
  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://pill4u.onrender.com/privacy');
    if (!await canLaunchUrl(url)) {
      _showError('Nie można otworzyć linku.');
      return;
    }
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
                      style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 48),

                    if (!isLogin) ...[
                      Text('Imię', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.primary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
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
                      controller: _emailController,
                      style: TextStyle(color: colorScheme.onSurface),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: isLogin ? 'twoj@email.pl' : 'adres@email.com',
                        prefixIcon: Icon(Icons.email_outlined, color: isDark ? Colors.grey : null),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text('Hasło', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.primary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: isLogin ? '••••••••' : 'Min. 8 znaków, litera i cyfra',
                        prefixIcon: Icon(Icons.lock_outline, color: isDark ? Colors.grey : null),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),

                    if (!isLogin) ...[
                      Text('Potwierdź hasło', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.primary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _confirmPasswordController,
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Powtórz hasło',
                          prefixIcon: Icon(Icons.lock_reset_outlined, color: isDark ? Colors.grey : null),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: acceptTerms,
                            activeColor: colorScheme.primary,
                            onChanged: (val) => setState(() => acceptTerms = val ?? false),
                          ),
                          // ✅ POPRAWKA: GestureDetector z HitTestBehavior.opaque
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
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
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isLogin ? 'Zaloguj się' : 'Zarejestruj się', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() {
                        isLogin = !isLogin;
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                      }),
                      child: Text(
                        isLogin ? 'Nie masz konta? Zarejestruj się' : 'Masz już konto? Zaloguj się',
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
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}