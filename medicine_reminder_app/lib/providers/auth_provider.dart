import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  Future<void> loadSavedAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    
    if (_token != null) {
      ApiService.setToken(_token!);
      // Load user data
      final userData = prefs.getString('user');
      if (userData != null) {
        // Parse and set user
      }
    }
    
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    int? age,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        age: age,
      );

      _token = response['data']['token'];
      _user = User.fromJson(response['data']);
      
      ApiService.setToken(_token!);
      await _saveAuth();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.login(
        email: email,
        password: password,
      );

      _token = response['data']['token'];
      _user = User.fromJson(response['data']);
      
      ApiService.setToken(_token!);
      await _saveAuth();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    ApiService.clearToken();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    notifyListeners();
  }

  Future<void> _saveAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
  }
}