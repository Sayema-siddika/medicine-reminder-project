class AdherenceLog {
  final String id;
  final String userId;
  final String medicationId;
  final DateTime scheduledTime;
  final DateTime? takenTime;
  final String status; // 'taken', 'missed', 'skipped'

  AdherenceLog({
    required this.id,
    required this.userId,
    required this.medicationId,
    required this.scheduledTime,
    this.takenTime,
    required this.status,
  });

  factory AdherenceLog.fromJson(Map<String, dynamic> json) {
    return AdherenceLog(
      id: json['_id'],
      userId: json['userId'],
      medicationId: json['medicationId'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      takenTime: json['takenTime'] != null 
        ? DateTime.parse(json['takenTime']) 
        : null,
      status: json['status'],
    );
  }
}