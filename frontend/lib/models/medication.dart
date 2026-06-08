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
    bool isLocal = json.containsKey('api_id');
    return Medication(
      id: isLocal ? json['id'] : null,
      apiId: isLocal ? json['api_id'] : json['id'],
      name: json['name'] ?? 'Lek',
      dosage: json['dosage'] ?? '',
      time: json['time'] ?? '00:00',
      days: json['days'] ?? '',
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