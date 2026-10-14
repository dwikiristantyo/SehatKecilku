import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'child_immunization_screen.dart';
import 'child_milestone_screen.dart';
import 'child_reminder_screen.dart';

class ChildDetailScreen extends StatefulWidget {
  final Map<String, dynamic> childData;

  const ChildDetailScreen({super.key, required this.childData});

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _growthRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGrowthRecords();
  }

  Future<void> _loadGrowthRecords() async {
    try {
      final response = await _supabase
          .from('growth_records')
          .select()
          .eq('child_id', widget.childData['id'])
          .order('recorded_at', ascending: false);

      setState(() {
        _growthRecords = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading growth records: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showAddGrowthDialog() {
    final weightController = TextEditingController();
    final heightController = TextEditingController();
    final headController = TextEditingController();
    final placeController = TextEditingController();
    final officerController = TextEditingController();
    
    // Default tanggal hari ini
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Tambah Catatan Pertumbuhan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pilihan Tanggal (Bisa Backdate)
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Tanggal Pengukuran',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Berat Badan (kg)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: heightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Tinggi/Panjang Badan (cm)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: headController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Lingkar Kepala (cm - Opsional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: placeController,
                      decoration: InputDecoration(
                        labelText: 'Tempat (Puskesmas/Klinik/RS/Posyandu)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: officerController,
                      decoration: InputDecoration(
                        labelText: 'Petugas In Charge (Dokter/Bidan/Petugas)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A9D8F),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (weightController.text.isEmpty || heightController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Berat dan Tinggi badan wajib diisi')),
                      );
                      return;
                    }

                    try {
                      await _supabase.from('growth_records').insert({
                        'child_id': widget.childData['id'],
                        'recorded_at': "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                        'weight_kg': double.parse(weightController.text),
                        'height_cm': double.parse(heightController.text),
                        'head_circumference_cm': headController.text.isNotEmpty 
                            ? double.parse(headController.text) 
                            : null,
                        'healthcare_provider_name': placeController.text.trim().isNotEmpty 
                            ? placeController.text.trim() 
                            : null,
                        'healthcare_provider_type': officerController.text.trim().isNotEmpty 
                            ? officerController.text.trim() 
                            : null,
                      });

                      if (mounted) {
                        Navigator.pop(context);
                        _loadGrowthRecords();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Catatan pertumbuhan berhasil ditambahkan!')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal menyimpan: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Widget untuk merender kurva grafik berat badan
  Widget _buildWeightChart() {
    if (_growthRecords.isEmpty) return const SizedBox.shrink();

    // Urutkan dari terlama ke terbaru untuk grafik yang benar
    final sortedRecords = List<Map<String, dynamic>>.from(_growthRecords)
      ..sort((a, b) => (a['recorded_at'] ?? '').compareTo(b['recorded_at'] ?? ''));

    List<FlSpot> spots = [];
    for (int i = 0; i < sortedRecords.length; i++) {
      final weight = (sortedRecords[i]['weight_kg'] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), weight));
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kurva Berat Badan (kg)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF264653)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: const FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF2A9D8F),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF2A9D8F).withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.childData;

    return Scaffold(
      appBar: AppBar(
        title: Text(child['full_name'] ?? 'Detail Anak'),
        backgroundColor: const Color(0xFF2A9D8F),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kartu Profil Anak
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFF2A9D8F).withValues(alpha: 0.2),
                      child: const Icon(Icons.face, size: 36, color: Color(0xFF2A9D8F)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child['full_name'] ?? '-',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text('Jenis Kelamin: ${child['gender']}'),
                          Text('Tanggal Lahir: ${child['birth_date']}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Navigation Bar / Menu Kesehatan Anak (Imunisasi, Milestone, Jadwal)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChildImmunizationScreen(childData: widget.childData),
                        ),
                      );
                    },
                    icon: const Icon(Icons.vaccines, size: 16),
                    label: const Text('Imunisasi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF264653),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChildMilestoneScreen(childData: widget.childData),
                        ),
                      );
                    },
                    icon: const Icon(Icons.emoji_events, size: 16),
                    label: const Text('Milestone'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE76F51),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChildReminderScreen(childData: widget.childData),
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications_active, size: 16),
                    label: const Text('Jadwal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A9D8F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tampilkan Grafik Berat Badan Jika Ada Data
            if (_growthRecords.isNotEmpty) ...[
              _buildWeightChart(),
              const SizedBox(height: 20),
            ],

            // Header Riwayat Pertumbuhan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat Pertumbuhan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF264653)),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddGrowthDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Catat Pengukuran'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A9D8F),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Daftar Riwayat Pertumbuhan
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _growthRecords.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada catatan pertumbuhan.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _growthRecords.length,
                          itemBuilder: (context, index) {
                            final record = _growthRecords[index];
                            final place = record['healthcare_provider_name'];
                            final officer = record['healthcare_provider_type'];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Tanggal: ${record['recorded_at']}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF264653)),
                                        ),
                                        if (place != null && place.toString().isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2A9D8F).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              place,
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF2A9D8F), fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Berat: ${record['weight_kg']} kg | Tinggi: ${record['height_cm']} cm${record['head_circumference_cm'] != null ? ' | LK: ${record['head_circumference_cm']} cm' : ''}',
                                    ),
                                    if (officer != null && officer.toString().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Petugas: $officer',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}