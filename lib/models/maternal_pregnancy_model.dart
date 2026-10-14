class MaternalPregnancyModel {
  final String id;
  final String profileId;
  final int pregnancyOrder;
  final DateTime hpht;
  final DateTime estimatedDeliveryDate;
  final String bloodType;
  final String rhesus;
  final bool isActive;
  final DateTime createdAt;

  MaternalPregnancyModel({
    required this.id,
    required this.profileId,
    required this.pregnancyOrder,
    required this.hpht,
    required this.estimatedDeliveryDate,
    required this.bloodType,
    required this.rhesus,
    required this.isActive,
    required this.createdAt,
  });

  factory MaternalPregnancyModel.fromJson(Map<String, dynamic> json) {
    return MaternalPregnancyModel(
      id: json['id'],
      profileId: json['profile_id'],
      pregnancyOrder: json['pregnancy_order'] ?? 1,
      hpht: DateTime.parse(json['hpht']),
      estimatedDeliveryDate: DateTime.parse(json['estimated_delivery_date']),
      bloodType: json['blood_type'] ?? 'Unknown',
      rhesus: json['rhesus'] ?? 'Unknown',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      'pregnancy_order': pregnancyOrder,
      'hpht': hpht.toIso8601String().split('T')[0],
      'estimated_delivery_date': estimatedDeliveryDate.toIso8601String().split('T')[0],
      'blood_type': bloodType,
      'rhesus': rhesus,
      'is_active': isActive,
    };
  }
}