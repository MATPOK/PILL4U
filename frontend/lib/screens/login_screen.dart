import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';

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
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');
    final nameRegex = RegExp(r'^[A-ZĄĆĘŁŃÓŚŹŻ][a-ząćęłńóśźż]+$');

    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showError('Wypełnij email i hasło!');
      return;
    }

    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showError('Podaj poprawny format adresu email!');
      return;
    }

    if (!isLogin) {
      if (_nameController.text.trim().isEmpty) {
        _showError('Wypełnij pole Imię!');
        return;
      }
      if (!nameRegex.hasMatch(_nameController.text.trim())) {
        _showError('Imię musi zaczynać się z dużej litery i zawierać tylko litery!');
        return;
      }
      if (!passwordRegex.hasMatch(_passwordController.text.trim())) {
        _showError('Hasło musi mieć min. 8 znaków, literę i cyfrę!');
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
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
      'email': _emailController.text.trim(),
      'password': _passwordController.text.trim(),
    };

    if (!isLogin) {
      requestBody['name'] = _nameController.text.trim();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Logo', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, color: Colors.black87)),
                    const SizedBox(height: 8),
                    const Text('Twój osobisty asystent lekowy', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.black54)),
                    const SizedBox(height: 48),

                    if (!isLogin) ...[
                      const Text('Imię', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Wpisz swoje imię',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const Text('Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: isLogin ? 'twoj@email.pl' : 'adres@email.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('Hasło', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        hintText: isLogin ? '••••••••' : 'Min. 8 znaków, litera i cyfra',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),

                    if (!isLogin) ...[
                      const Text('Potwierdź hasło', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          hintText: 'Powtórz hasło',
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: acceptTerms,
                            onChanged: (val) => setState(() => acceptTerms = val ?? false),
                          ),
                          const Expanded(
                            child: Text('Akceptuję politykę prywatności oraz regulamin', style: TextStyle(fontSize: 12)),
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
                children: const [
                  Icon(Icons.security, size: 16, color: Colors.black54),
                  SizedBox(width: 8),
                  Text('Twoje dane są bezpieczne i zaszyfrowane', style: TextStyle(color: Colors.black54, fontSize: 12)),
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