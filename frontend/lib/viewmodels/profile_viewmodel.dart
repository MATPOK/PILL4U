import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/database_helper.dart';
import '../helpers/token_storage.dart';

class ProfileViewModel extends ChangeNotifier {
  Future<void> logout() async {
    await TokenStorage.deleteToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await DatabaseHelper.instance.clearAllData();
    notifyListeners();
  }
}
