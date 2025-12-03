import 'dart:convert';
// Required for Platform.isAndroid
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb; // Required for kIsWeb

class ApiService {
  // ------------------------------------------------------------
  // CONFIGURATION
  // ------------------------------------------------------------
  
  // 1. The Live Render URL (Works everywhere)
  // FIXED: Added /api to match backend routes
  static const String _prodUrl = 'https://medicine-reminder-project-1.onrender.com/api';
  
  // 2. The Localhost URLs (For testing on your own computer later)
  static const String _localUrlWeb = 'http://localhost:10000/api'; 
  static const String _localUrlAndroid = 'http://10.0.2.2:10000/api'; 

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
    try {
      print('📡 Calling: $baseUrl/auth/register');
      
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
      ).timeout(Duration(seconds: 30));

      print('✅ Response: ${response.statusCode}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Registration failed');
      }
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('📡 Calling: $baseUrl/auth/login');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(Duration(seconds: 30));

      print('✅ Response: ${response.statusCode}');
      print('📄 Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

  // --- MEDICATIONS ---

  static Future<List<dynamic>> getMedications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/medications'),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to load medications');
      }
    } catch (e) {
      print('❌ Error loading medications: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> addMedication(Map<String, dynamic> medicationData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/medications'),
        headers: _getHeaders(),
        body: jsonEncode(medicationData),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to add medication');
      }
    } catch (e) {
      print('❌ Error adding medication: $e');
      rethrow;
    }
  }

  static Future<void> deleteMedication(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/medications/$id'),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete medication');
      }
    } catch (e) {
      print('❌ Error deleting medication: $e');
      rethrow;
    }
  }

  // --- LOGGING & ANALYTICS ---

  static Future<Map<String, dynamic>> logAdherence({
    required String medicationId,
    required DateTime scheduledTime,
    required String status,
    DateTime? takenTime,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/medications/log'),
        headers: _getHeaders(),
        body: jsonEncode({
          'medicationId': medicationId,
          'scheduledTime': scheduledTime.toIso8601String(),
          'status': status,
          'takenTime': takenTime?.toIso8601String(),
        }),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to log adherence');
      }
    } catch (e) {
      print('❌ Error logging adherence: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getAdherenceStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/adherence'),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to load statistics');
      }
    } catch (e) {
      print('❌ Error loading stats: $e');
      rethrow;
    }
  }

  // --- AI MACHINE LEARNING FEATURES ---

  // 1. Risk Prediction (For Home Screen Lightbulb)
  static Future<Map<String, dynamic>> getAiPrediction({
    required int medsCount,
    required double pastAdherence,
  }) async {
    try {
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
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('AI Brain is sleeping (Server Error)');
      }
    } catch (e) {
      print('❌ AI Prediction Error: $e');
      rethrow;
    }
  }

  // 2. Smart Time Suggestion (For Add Medication Screen)
  static Future<String> getOptimalTime({
    required int medsCount,
    required double pastAdherence,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ml/suggest-times'),
        headers: _getHeaders(),
        body: jsonEncode({
          'num_daily_meds': medsCount,
          'past_adherence_rate': pastAdherence
        }),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // The AI returns a list: [{time: "08:00", prob: 0.9}, ...]
        // We take the first one (best one)
        List<dynamic> suggestions = data['suggested_times']; 
        if (suggestions.isNotEmpty) {
          return suggestions[0]['time']; // Returns "08:00"
        }
      }
    } catch (e) {
      print('❌ AI Time Suggestion Error: $e');
    }
    return "08:00"; // Fallback if AI fails
  }
}