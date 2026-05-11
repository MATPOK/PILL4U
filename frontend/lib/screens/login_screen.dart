import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  bool acceptTerms = false;

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
                      decoration: InputDecoration(
                        hintText: isLogin ? '••••••••' : 'Min. 8 znaków',
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
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isLogin ? 'Zaloguj się' : 'Zarejestruj się', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => isLogin = !isLogin),
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
}