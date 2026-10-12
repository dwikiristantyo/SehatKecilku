import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
          .order('measurement_date', ascending: false);

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
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Tambah Catatan Pertumbuhan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Berat Badan (kg)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Tinggi/Panjang Badan (cm)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: headController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Lingkar Kepala (cm - Opsional)'),
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
                  'recorded_at': selectedDate.toIso8601String().split('T')[0], // atau sesuaikan nama kolom
                  'weight_kg': double.parse(weightController.text),
                  'height_cm': double.parse(heightController.text),
                  'head_circumference_cm': headController.text.isNotEmpty 
                  ? double.parse(headController.text) 
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
            // Header Info Anak
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFF2A9D8F).withOpacity(0.2),
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
            const SizedBox(height: 24),
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
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: const Icon(Icons.monitor_weight, color: Color(0xFF2A9D8F)),
                                title: Text('Tanggal: ${record['measurement_date']}'),
                                subtitle: Text(
                                  'Berat: ${record['weight_kg']} kg | Tinggi: ${record['height_cm']} cm',
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