class Medication {
  final int? id;
  final int? apiId;
  final String name;
  final String dosage;
  final String time;
  final String days;

  Medication({
    this.id,
    this.apiId,
    required this.name,
    required this.dosage,
    required this.time,
    required this.days,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      apiId: json['api_id'] ?? json['id'], // API uses 'id', local DB uses 'api_id'
      name: json['name'],
      dosage: json['dosage'],
      time: json['time'],
      days: json['days'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (apiId != null) 'api_id': apiId,
      'name': name,
      'dosage': dosage,
      'time': time,
      'days': days,
    };
  }

  // Helper for API requests which might expect different keys
  Map<String, dynamic> toApiJson() {
    return {
      'name': name,
      'dosage': dosage,
      'time': time,
      'days': days,
    };
  }

  Medication copyWith({int? apiId}) {
    return Medication(
      id: id,
      apiId: apiId ?? this.apiId,
      name: name,
      dosage: dosage,
      time: time,
      days: days,
    );
  }
}
