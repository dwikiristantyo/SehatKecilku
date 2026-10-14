class ChildIllnessModel {
  final String id;
  final String childId;
  final DateTime recordedDate;
  final String illnessType;
  final List<String> symptoms;
  final String? treatmentGiven;
  final bool isReferredToHospital;
  final String? notes;
  final DateTime createdAt;

  ChildIllnessModel({
    required this.id,
    required this.childId,
    required this.recordedDate,
    required this.illnessType,
    required this.symptoms,
    this.treatmentGiven,
    required this.isReferredToHospital,
    this.notes,
    required this.createdAt,
  });

  factory ChildIllnessModel.fromJson(Map<String, dynamic> json) {
    return ChildIllnessModel(
      id: json['id'],
      childId: json['child_id'],
      recordedDate: DateTime.parse(json['recorded_date']),
      illnessType: json['illness_type'],
      symptoms: json['symptoms'] != null ? List<String>.from(json['symptoms']) : [],
      treatmentGiven: json['treatment_given'],
      isReferredToHospital: json['is_referred_to_hospital'] ?? false,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'child_id': childId,
      'recorded_date': recordedDate.toIso8601String().split('T')[0],
      'illness_type': illnessType,
      'symptoms': symptoms,
      'treatment_given': treatmentGiven,
      'is_referred_to_hospital': isReferredToHospital,
      'notes': notes,
    };
  }
}