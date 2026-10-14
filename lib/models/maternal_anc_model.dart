class MaternalAncModel {
  final String id;
  final String pregnancyId;
  final DateTime visitDate;
  final int trimester;
  final int? gestationalAgeWeeks;
  final double? weightKg;
  final String? bloodPressure;
  final double? hbLevel;
  final double? fundalHeightCm;
  final int? fetalHeartRate;
  final String? complaints;
  final int? ttdTabletsGiven;
  final String? counselingNotes;
  final String? healthcareProviderName;
  final DateTime createdAt;

  MaternalAncModel({
    required this.id,
    required this.pregnancyId,
    required this.visitDate,
    required this.trimester,
    this.gestationalAgeWeeks,
    this.weightKg,
    this.bloodPressure,
    this.hbLevel,
    this.fundalHeightCm,
    this.fetalHeartRate,
    this.complaints,
    this.ttdTabletsGiven,
    this.counselingNotes,
    this.healthcareProviderName,
    required this.createdAt,
  });

  factory MaternalAncModel.fromJson(Map<String, dynamic> json) {
    return MaternalAncModel(
      id: json['id'],
      pregnancyId: json['pregnancy_id'],
      visitDate: DateTime.parse(json['visit_date']),
      trimester: json['trimester'] ?? 1,
      gestationalAgeWeeks: json['gestational_age_weeks'],
      weightKg: json['weight_kg'] != null ? (json['weight_kg'] as num).toDouble() : null,
      bloodPressure: json['blood_pressure'],
      hbLevel: json['hb_level'] != null ? (json['hb_level'] as num).toDouble() : null,
      fundalHeightCm: json['fundal_height_cm'] != null ? (json['fundal_height_cm'] as num).toDouble() : null,
      fetalHeartRate: json['fetal_heart_rate'],
      complaints: json['complaints'],
      ttdTabletsGiven: json['ttd_tablets_given'],
      counselingNotes: json['counseling_notes'],
      healthcareProviderName: json['healthcare_provider_name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pregnancy_id': pregnancyId,
      'visit_date': visitDate.toIso8601String().split('T')[0],
      'trimester': trimester,
      'gestational_age_weeks': gestationalAgeWeeks,
      'weight_kg': weightKg,
      'blood_pressure': bloodPressure,
      'hb_level': hbLevel,
      'fundal_height_cm': fundalHeightCm,
      'fetal_heart_rate': fetalHeartRate,
      'complaints': complaints,
      'ttd_tablets_given': ttdTabletsGiven,
      'counseling_notes': counselingNotes,
      'healthcare_provider_name': healthcareProviderName,
    };
  }
}