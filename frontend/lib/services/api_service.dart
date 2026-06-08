import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication.dart';
import '../models/history_entry.dart';

class ApiService {
  static const String baseUrl = 'https://pill4u.onrender.com/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> login(String email, String password) async {
    return await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
  }

  Future<http.Response> register(String email, String password, String name) async {
    return await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'name': name}),
    );
  }

  Future<http.Response> getMe() async {
    return await http.get(
      Uri.parse('$baseUrl/user/me'),
      headers: await _getHeaders(),
    );
  }

  Future<http.Response> getMedications() async {
    return await http.get(
      Uri.parse('$baseUrl/medications'),
      headers: await _getHeaders(),
    );
  }

  Future<http.Response> postMedication(Medication medication) async {
    return await http.post(
      Uri.parse('$baseUrl/medications'),
      headers: await _getHeaders(),
      body: jsonEncode(medication.toApiJson()),
    );
  }

  Future<http.Response> deleteMedication(int apiId) async {
    return await http.delete(
      Uri.parse('$baseUrl/medications/$apiId'),
      headers: await _getHeaders(),
    );
  }

  Future<http.Response> getHistory() async {
    return await http.get(
      Uri.parse('$baseUrl/history'),
      headers: await _getHeaders(),
    );
  }

  Future<http.Response> postHistory(HistoryEntry historyItem) async {
    return await http.post(
      Uri.parse('$baseUrl/history'),
      headers: await _getHeaders(),
      body: jsonEncode(historyItem.toApiJson()),
    );
  }

  Future<http.Response> deleteHistory(int apiHistoryId) async {
    return await http.delete(
      Uri.parse('$baseUrl/history/$apiHistoryId'),
      headers: await _getHeaders(),
    );
  }

  Future<http.Response> getHistoryStats() async {
    return await http.get(
      Uri.parse('$baseUrl/history/stats'),
      headers: await _getHeaders(),
    );
  }
}
