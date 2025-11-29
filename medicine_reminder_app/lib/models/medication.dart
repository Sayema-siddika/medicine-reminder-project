class Medication {
  final String id;
  final String userId;
  final String name;
  final String dosage;
  final String frequency;
  final List<String> times;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final bool isActive;

  Medication({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.times,
    required this.startDate,
    this.endDate,
    this.notes,
    this.isActive = true,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['_id'], // MongoDB uses '_id'
      userId: json['userId'],
      name: json['name'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      // Ensure 'times' is treated as a list of strings
      times: List<String>.from(json['times']),
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      notes: json['notes'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'times': times,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'notes': notes,
    };
  }
}