import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class LoginViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool isLogin = true;
  bool acceptTerms = false;
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();

  void toggleMode() {
    isLogin = !isLogin;
    passwordController.clear();
    confirmPasswordController.clear();
    isPasswordVisible = false;
    isConfirmPasswordVisible = false;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible = !isConfirmPasswordVisible;
    notifyListeners();
  }

  void setAcceptTerms(bool value) {
    acceptTerms = value;
    notifyListeners();
  }

  Future<String?> submit() async {
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');
    final nameRegex = RegExp(r'^[A-ZĄĆĘŁŃÓŚŹŻ][a-ząćęłńóśźż]+$');

    if (email.isEmpty || password.isEmpty) {
      return 'Wypełnij email i hasło!';
    }

    if (!emailRegex.hasMatch(email)) {
      return 'Podaj poprawny format adresu email!';
    }

    if (!isLogin) {
      if (name.isEmpty) {
        return 'Wypełnij pole Imię!';
      }
      if (!nameRegex.hasMatch(name)) {
        return 'Imię musi zaczynać się z dużej litery i zawierać tylko litery!';
      }
      if (!passwordRegex.hasMatch(password)) {
        return 'Hasło musi mieć min. 8 znaków, literę i cyfrę!';
      }
      if (password != confirmPasswordController.text) {
        return 'Podane hasła nie są identyczne!';
      }
      if (!acceptTerms) {
        return 'Musisz zaakceptować regulamin!';
      }
    }

    isLoading = true;
    notifyListeners();

    try {
      final response = isLogin
          ? await _apiService.login(email, password)
          : await _apiService.register(email, password, name);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (isLogin) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', responseData['token']);
          return null; // Success login
        } else {
          isLogin = true;
          passwordController.clear();
          confirmPasswordController.clear();
          return 'SUCCESS_REGISTER';
        }
      } else {
        return responseData['error'] ?? 'Nieprawidłowe dane';
      }
    } catch (error) {
      return 'Błąd połączenia z serwerem.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    super.dispose();
  }
}
