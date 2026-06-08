class HistoryEntry {
  final int? id;
  final int? apiId;
  final int medicationId;
  final String medicationName;
  final String status;
  final String takenAt;

  HistoryEntry({
    this.id,
    this.apiId,
    required this.medicationId,
    required this.medicationName,
    required this.status,
    required this.takenAt,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'],
      apiId: json['api_id'] ?? json['id'], // API uses 'id', local DB uses 'api_id'
      medicationId: json['medication_id'] ?? json['medicationId'],
      medicationName: json['medication_name'] ?? json['medicationName'],
      status: json['status'],
      takenAt: json['taken_at'] ?? json['takenAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (apiId != null) 'api_id': apiId,
      'medication_id': medicationId,
      'medication_name': medicationName,
      'status': status,
      'taken_at': takenAt,
    };
  }

  Map<String, dynamic> toApiJson() {
    return {
      'medicationId': medicationId,
      'medicationName': medicationName,
      'status': status,
      'takenAt': takenAt,
    };
  }
}
