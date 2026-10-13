import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChildImmunizationScreen extends StatefulWidget {
  final Map<String, dynamic> childData;

  const ChildImmunizationScreen({super.key, required this.childData});

  @override
  State<ChildImmunizationScreen> createState() => _ChildImmunizationScreenState();
}

class _ChildImmunizationScreenState extends State<ChildImmunizationScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _allImmunizations = [];
  List<Map<String, dynamic>> _childLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchImmunizationData();
  }

  Future<void> _fetchImmunizationData() async {
    try {
      // 1. Ambil seluruh master data imunisasi
      final immunizationsRes = await _supabase
          .from('immunizations')
          .select()
          .order('recommended_age_months', ascending: true);

      // 2. Ambil log imunisasi yang sudah dicatat untuk anak ini
      final logsRes = await _supabase
          .from('child_immunization_logs')
          .select()
          .eq('child_id', widget.childData['id']);

      setState(() {
        _allImmunizations = List<Map<String, dynamic>>.from(immunizationsRes);
        _childLogs = List<Map<String, dynamic>>.from(logsRes);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching immunizations: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showLogDialog(Map<String, dynamic> immunization, Map<String, dynamic>? existingLog) {
    final locationController = TextEditingController(text: existingLog?['healthcare_location'] ?? '');
    final batchController = TextEditingController(text: existingLog?['batch_number'] ?? '');
    final adminNameController = TextEditingController(text: existingLog?['administrator_name'] ?? '');
    DateTime selectedDate = existingLog != null && existingLog['administered_date'] != null
        ? DateTime.parse(existingLog['administered_date'])
        : DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existingLog == null ? 'Catat Imunisasi' : 'Edit Imunisasi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  immunization['vaccine_name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2A9D8F)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Lokasi Faskes / Klinik (Opsional)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: batchController,
                  decoration: const InputDecoration(labelText: 'Nomor Batch Vaksin (Opsional)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: adminNameController,
                  decoration: const InputDecoration(labelText: 'Nama Pemberi / Vaksinator (Opsional)'),
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
                try {
                  final dataToSave = {
                    'child_id': widget.childData['id'],
                    'immunization_id': immunization['id'],
                    'administered_date': selectedDate.toIso8601String().split('T')[0],
                    'healthcare_location': locationController.text.isNotEmpty ? locationController.text : null,
                    'batch_number': batchController.text.isNotEmpty ? batchController.text : null,
                    'administrator_name': adminNameController.text.isNotEmpty ? adminNameController.text : null,
                  };

                  if (existingLog == null) {
                    await _supabase.from('child_immunization_logs').insert(dataToSave);
                  } else {
                    await _supabase
                        .from('child_immunization_logs')
                        .update(dataToSave)
                        .eq('id', existingLog['id']);
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    _fetchImmunizationData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Status imunisasi berhasil disimpan!')),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Imunisasi: ${widget.childData['full_name']}'),
        backgroundColor: const Color(0xFF2A9D8F),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allImmunizations.isEmpty
              ? const Center(child: Text('Belum ada data master imunisasi.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _allImmunizations.length,
                  itemBuilder: (context, index) {
                    final item = _allImmunizations[index];
                    
                    // Cek apakah vaksin ini sudah dicatat untuk anak
                    final existingLog = _childLogs.firstWhere(
                      (log) => log['immunization_id'] == item['id'],
                      orElse: () => {},
                    );

                    final bool isCompleted = existingLog.isNotEmpty;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCompleted ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                          child: Icon(
                            isCompleted ? Icons.check : Icons.access_time,
                            color: isCompleted ? Colors.green : Colors.orange,
                          ),
                        ),
                        title: Text(
                          item['vaccine_name'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Rekomendasi Usia: ${item['recommended_age_months']} Bulan\n'
                          'Status: ${isCompleted ? 'Sudah (${existingLog['administered_date']})' : 'Belum Diberikan'}',
                        ),
                        isThreeLine: true,
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCompleted ? Colors.grey.shade200 : const Color(0xFF2A9D8F),
                            foregroundColor: isCompleted ? Colors.black87 : Colors.white,
                          ),
                          onPressed: () => _showLogDialog(item, isCompleted ? existingLog : null),
                          child: Text(isCompleted ? 'Edit' : 'Catat'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}