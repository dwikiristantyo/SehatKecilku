import 'dart:math' as math;

import 'package:flutter/material.dart';

class ChildDisplayStyle {
  final String genderLabel;
  final Color accentColor;
  final Color backgroundColor;
  final IconData icon;

  const ChildDisplayStyle({
    required this.genderLabel,
    required this.accentColor,
    required this.backgroundColor,
    required this.icon,
  });
}

ChildDisplayStyle childDisplayStyle(Object? genderValue) {
  final gender = genderValue?.toString().trim().toLowerCase();
  if (gender == 'female' || gender == 'perempuan') {
    return const ChildDisplayStyle(
      genderLabel: 'Perempuan',
      accentColor: Color(0xFFC65078),
      backgroundColor: Color(0xFFFFE8EF),
      icon: Icons.girl,
    );
  }
  if (gender == 'male' || gender == 'laki-laki') {
    return const ChildDisplayStyle(
      genderLabel: 'Laki-laki',
      accentColor: Color(0xFF3978B8),
      backgroundColor: Color(0xFFE7F2FC),
      icon: Icons.boy,
    );
  }
  return const ChildDisplayStyle(
    genderLabel: 'Tidak diketahui',
    accentColor: Color(0xFF2A9D8F),
    backgroundColor: Colors.white,
    icon: Icons.child_care,
  );
}

DateTime? parseChildBirthDate(Object? value) {
  if (value == null) return null;
  try {
    return DateTime.parse(value.toString());
  } on FormatException {
    return null;
  }
}

String formatChildBirthDate(Object? value) {
  final birthDate = parseChildBirthDate(value);
  if (birthDate == null) return 'Tidak tersedia';
  return '${birthDate.day.toString().padLeft(2, '0')}/'
      '${birthDate.month.toString().padLeft(2, '0')}/${birthDate.year}';
}

String formatChildAge(Object? value, {DateTime? today}) {
  final birthDate = parseChildBirthDate(value);
  if (birthDate == null) return 'Usia tidak tersedia';

  final currentDate = today ?? DateTime.now();
  var months =
      (currentDate.year - birthDate.year) * 12 +
      currentDate.month -
      birthDate.month;
  final lastDayOfCurrentMonth = DateTime(
    currentDate.year,
    currentDate.month + 1,
    0,
  ).day;
  final anniversaryDay = math.min(birthDate.day, lastDayOfCurrentMonth);
  if (currentDate.day < anniversaryDay) months--;
  if (months < 0) return 'Usia belum tersedia';

  final years = months ~/ 12;
  final remainingMonths = months % 12;
  return 'Usia: $years Tahun $remainingMonths Bulan';
}
