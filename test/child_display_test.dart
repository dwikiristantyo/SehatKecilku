import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sehat_kecilku/features/dashboard/child_display.dart';

void main() {
  group('formatChildAge', () {
    test('formats full years and remaining months', () {
      expect(
        formatChildAge('2024-08-15', today: DateTime(2026, 10, 15)),
        'Usia: 2 Tahun 2 Bulan',
      );
    });

    test('does not count an incomplete month', () {
      expect(
        formatChildAge('2024-01-15', today: DateTime(2024, 2, 14)),
        'Usia: 0 Tahun 0 Bulan',
      );
    });

    test('returns unavailable for invalid or future dates', () {
      expect(formatChildAge('invalid'), 'Usia tidak tersedia');
      expect(
        formatChildAge('2026-10-16', today: DateTime(2026, 10, 15)),
        'Usia belum tersedia',
      );
    });
  });

  test('uses pastel style for each gender', () {
    expect(
      childDisplayStyle('female').backgroundColor,
      const Color(0xFFFFE8EF),
    );
    expect(childDisplayStyle('male').backgroundColor, const Color(0xFFE7F2FC));
  });
}
