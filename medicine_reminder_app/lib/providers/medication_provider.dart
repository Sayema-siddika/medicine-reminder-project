import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../services/api_service.dart';

class MedicationProvider with ChangeNotifier {
  List<Medication> _medications = [];
  bool _isLoading = false;

  List<Medication> get medications => _medications;
  bool get isLoading => _isLoading;

  Future<void> loadMedications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.getMedications();
      _medications = data.map((json) => Medication.fromJson(json)).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addMedication(Medication medication) async {
    try {
      await ApiService.addMedication(medication.toJson());
      await loadMedications(); // Reload list
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMedication(String id) async {
    try {
      await ApiService.deleteMedication(id);
      _medications.removeWhere((med) => med.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}