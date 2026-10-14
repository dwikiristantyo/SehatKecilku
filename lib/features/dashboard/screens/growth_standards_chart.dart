import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GrowthStandardsChart extends StatefulWidget {
  final String childName;
  final String childGender;
  final String childBirthDate;
  final List<Map<String, dynamic>> growthRecords;

  const GrowthStandardsChart({
    super.key,
    required this.childName,
    required this.childGender,
    required this.childBirthDate,
    required this.growthRecords,
  });

  @override
  State<GrowthStandardsChart> createState() => _GrowthStandardsChartState();
}

class _GrowthStandardsChartState extends State<GrowthStandardsChart> {
  static const _standardSeries = <(String, String, Color)>[
    ('sd3neg', '-3 SD', Color(0xFFC94C4C)),
    ('sd2neg', '-2 SD', Color(0xFFE58A45)),
    ('sd1neg', '-1 SD', Color(0xFFE5B84B)),
    ('median', 'Median', Color(0xFF238B7A)),
    ('sd1pos', '+1 SD', Color(0xFF4D8DBD)),
    ('sd2pos', '+2 SD', Color(0xFF5367A5)),
    ('sd3pos', '+3 SD', Color(0xFF805A91)),
  ];

  List<Map<String, dynamic>> _standards = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadStandards();
  }

  Future<void> _loadStandards() async {
    final gender = widget.childGender.trim().toLowerCase();
    final genderCode = switch (gender) {
      'male' || 'laki-laki' || 'l' => 'L',
      'female' || 'perempuan' || 'p' => 'P',
      _ => null,
    };

    if (genderCode == null) {
      setState(() {
        _loadError = 'Jenis kelamin anak belum tersedia untuk standar BB/U.';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('growth_standards')
          .select()
          .eq('indicator', 'BB_U')
          .eq('gender', genderCode)
          .order('age_in_months');

      if (!mounted) return;
      setState(() {
        _standards = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  DateTime? _recordDate(Map<String, dynamic> record) {
    final value = record['recorded_at']?.toString();
    return value == null ? null : DateTime.tryParse(value);
  }

  int? _ageInMonths(DateTime measuredAt) {
    final birthDate = DateTime.tryParse(widget.childBirthDate);
    if (birthDate == null) return null;

    var months =
        (measuredAt.year - birthDate.year) * 12 +
        measuredAt.month -
        birthDate.month;
    if (measuredAt.day < birthDate.day) months--;
    return months;
  }

  List<FlSpot> _recordSpots() {
    final records = List<Map<String, dynamic>>.from(widget.growthRecords)
      ..sort((a, b) {
        final left = _recordDate(a);
        final right = _recordDate(b);
        if (left == null || right == null) return 0;
        return left.compareTo(right);
      });

    return records
        .map((record) {
          final date = _recordDate(record);
          final weight = (record['weight_kg'] as num?)?.toDouble();
          final age = date == null ? null : _ageInMonths(date);
          if (weight == null || age == null || age < 0 || age > 60) return null;
          return FlSpot(age.toDouble(), weight);
        })
        .whereType<FlSpot>()
        .toList();
  }

  Map<String, dynamic>? _latestRecord() {
    final records = List<Map<String, dynamic>>.from(widget.growthRecords)
      ..sort((a, b) {
        final left = _recordDate(a);
        final right = _recordDate(b);
        if (left == null || right == null) return 0;
        return left.compareTo(right);
      });
    return records.isEmpty ? null : records.last;
  }

  Widget _buildLegendItem(Color color, String label, {bool isRecord = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isRecord)
          Icon(Icons.circle, size: 9, color: color)
        else
          Container(width: 15, height: 3, color: color),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildInterpretation() {
    final latest = _latestRecord();
    if (latest == null) {
      return const Text('Belum ada record berat badan untuk dibandingkan.');
    }

    final date = _recordDate(latest);
    final weight = (latest['weight_kg'] as num?)?.toDouble();
    final age = date == null ? null : _ageInMonths(date);
    if (date == null || weight == null || age == null) {
      return const Text('Data record berat badan terakhir tidak lengkap.');
    }

    final standard = _standards.cast<Map<String, dynamic>?>().firstWhere(
      (row) => (row?['age_in_months'] as num?)?.toInt() == age,
      orElse: () => null,
    );

    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-${date.year}';
    final measurement =
        'Record terakhir ${weight.toStringAsFixed(1)} kg pada usia $age bulan ($dateLabel).';

    if (age < 0 || age > 60) {
      return Text('$measurement Standar BB/U tersedia untuk usia 0-60 bulan.');
    }
    if (standard == null) {
      return Text('$measurement Data standar BB/U untuk usia ini belum tersedia.');
    }

    final sd3neg = (standard['sd3neg'] as num).toDouble();
    final sd2neg = (standard['sd2neg'] as num).toDouble();
    final sd1pos = (standard['sd1pos'] as num).toDouble();
    final (category, color) = weight < sd3neg
        ? ('Di bawah -3 SD: berat badan sangat kurang', const Color(0xFFC94C4C))
        : weight < sd2neg
        ? ('-3 SD hingga < -2 SD: berat badan kurang', const Color(0xFFE58A45))
        : weight <= sd1pos
        ? ('-2 SD hingga +1 SD: dalam rentang normal', const Color(0xFF238B7A))
        : ('Di atas +1 SD: perlu penilaian lanjutan', const Color(0xFF5367A5));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(measurement),
        const SizedBox(height: 4),
        Text(
          'BB/U: $category. Ini adalah indikator pemantauan, bukan diagnosis.',
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordSpots = _recordSpots();
    final standardLines = _standardSeries
        .map((series) {
          final (field, _, color) = series;
          final spots = _standards
              .map((row) {
                final age = (row['age_in_months'] as num?)?.toDouble();
                final value = (row[field] as num?)?.toDouble();
                if (age == null || value == null) return null;
                return FlSpot(age, value);
              })
              .whereType<FlSpot>()
              .toList();

          return LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: field == 'median' ? 2.2 : 1.2,
            dotData: const FlDotData(show: false),
          );
        })
        .where((line) => line.spots.isNotEmpty)
        .toList();

    final allValues = <double>[
      for (final row in _standards)
        for (final (field, _, _) in _standardSeries)
          if (row[field] is num) (row[field] as num).toDouble(),
      for (final spot in recordSpots) spot.y,
    ];

    final minY = allValues.isEmpty
        ? 0.0
        : allValues.reduce((left, right) => left < right ? left : right) - 0.5;
    final maxY = allValues.isEmpty
        ? 1.0
        : allValues.reduce((left, right) => left > right ? left : right) + 0.5;

    final chartLines = [
      ...standardLines,
      if (recordSpots.isNotEmpty)
        LineChartBarData(
          spots: recordSpots,
          isCurved: false,
          color: const Color(0xFF263238),
          barWidth: 3,
          dotData: const FlDotData(show: true),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Berat Badan Menurut Umur (BB/U)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF264653),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Standar WHO 0-60 bulan · ${widget.childName}',
            style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),
          const SizedBox(height: 8),
          if (_isLoading)
            const LinearProgressIndicator()
          else if (_loadError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Standar BB/U tidak dapat dimuat: $_loadError',
                style: const TextStyle(color: Color(0xFFC94C4C), fontSize: 12),
              ),
            )
          else if (_standards.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Data standar BB/U belum tersedia untuk gender ini.',
                style: TextStyle(color: Colors.blueGrey, fontSize: 12),
              ),
            ),
          if (chartLines.isNotEmpty) ...[
            SizedBox(
              height: 230,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 60,
                  minY: minY,
                  maxY: maxY,
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text(
                        'Usia (bulan)',
                        style: TextStyle(fontSize: 10),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 12,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: chartLines,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (_standards.isNotEmpty)
                  for (final series in _standardSeries)
                    _buildLegendItem(series.$3, series.$2),
                if (recordSpots.isNotEmpty)
                  _buildLegendItem(
                    const Color(0xFF263238),
                    'Record ${widget.childName}',
                    isRecord: true,
                  ),
              ],
            ),
          ] else if (!_isLoading && _loadError == null)
            const Text(
              'Belum ada data untuk ditampilkan pada rentang standar.',
            ),
          const Divider(height: 24),
          _buildInterpretation(),
        ],
      ),
    );
  }
}
