import 'dart:convert';
import 'dart:io'; // Required for Platform.isAndroid
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb; // Required for kIsWeb

class ApiService {
  // ------------------------------------------------------------
  // CONFIGURATION
  // ------------------------------------------------------------
  
  // 1. The Live Render URL (Works everywhere)
  static const String _prodUrl = 'https://medicine-reminder-project-1.onrender.com';
  
  // 2. The Localhost URLs (For testing on your own computer later)
  static const String _localUrlWeb = 'http://localhost:10000'; 
  static const String _localUrlAndroid = 'http://10.0.2.2:10000'; 

  // ------------------------------------------------------------
  // SMART URL DETECTOR
  // ------------------------------------------------------------
  // This logic automatically picks the right URL based on the device.
  // Currently, it just returns _prodUrl for everything because you are live!
  static String get baseUrl {
    // CURRENT MODE: PRODUCTION (Render)
    return _prodUrl;

    // DEBUG MODE: If you ever go back to localhost, uncomment this:
    /*
    if (kIsWeb) {
      return _localUrlWeb;       // Chrome
    } else if (Platform.isAndroid) {
      return _localUrlAndroid;   // Android Emulator
    } else {
      return _localUrlWeb;       // iOS/Other
    }
    */
  }
  
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static void clearToken() {
    _token = null;
  }

  static Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    
    return headers;
  }

  // --- AUTHENTICATION ---

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    int? age,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'age': age,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Registration failed');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Login failed');
    }
  }

  // --- MEDICATIONS ---

  static Future<List<dynamic>> getMedications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/medications'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load medications');
    }
  }

  static Future<Map<String, dynamic>> addMedication(Map<String, dynamic> medicationData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/medications'),
      headers: _getHeaders(),
      body: jsonEncode(medicationData),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to add medication');
      } catch (e) {
        throw Exception('Failed to add medication: ${response.body}');
      }
    }
  }

  static Future<void> deleteMedication(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/medications/$id'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete medication');
    }
  }

  // --- LOGGING & ANALYTICS ---

  static Future<Map<String, dynamic>> logAdherence({
    required String medicationId,
    required DateTime scheduledTime,
    required String status,
    DateTime? takenTime,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/medications/log'),
      headers: _getHeaders(),
      body: jsonEncode({
        'medicationId': medicationId,
        'scheduledTime': scheduledTime.toIso8601String(),
        'status': status,
        'takenTime': takenTime?.toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to log adherence');
    }
  }

  static Future<Map<String, dynamic>> getAdherenceStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/adherence'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load statistics');
    }
  }

  // --- AI MACHINE LEARNING FEATURES ---

  // 1. Risk Prediction (For Home Screen Lightbulb)
  static Future<Map<String, dynamic>> getAiPrediction({
    required int medsCount,
    required double pastAdherence,
  }) async {
    final now = DateTime.now();
    
    final response = await http.post(
      Uri.parse('$baseUrl/ml/predict-risk'),
      headers: _getHeaders(),
      body: jsonEncode({
        'hour_of_day': now.hour,
        'day_of_week': now.weekday - 1, 
        'num_daily_meds': medsCount,
        'past_adherence_rate': pastAdherence,
        'hours_since_last_dose': 6 
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('AI Brain is sleeping (Server Error)');
    }
  }

  // 2. Smart Time Suggestion (For Add Medication Screen)
  static Future<String> getOptimalTime({
    required int medsCount,
    required double pastAdherence,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ml/suggest-times'),
      headers: _getHeaders(),
      body: jsonEncode({
        'num_daily_meds': medsCount,
        'past_adherence_rate': pastAdherence
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // The AI returns a list: [{time: "08:00", prob: 0.9}, ...]
      // We take the first one (best one)
      List<dynamic> suggestions = data['suggested_times']; 
      if (suggestions.isNotEmpty) {
        return suggestions[0]['time']; // Returns "08:00"
      }
    }
    return "08:00"; // Fallback if AI fails
  }
}