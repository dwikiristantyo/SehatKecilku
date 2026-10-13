import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChildReminderScreen extends StatefulWidget {
  final Map<String, dynamic> childData;

  const ChildReminderScreen({super.key, required this.childData});

  @override
  State<ChildReminderScreen> createState() => _ChildReminderScreenState();
}

class _ChildReminderScreenState extends State<ChildReminderScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _scheduleList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateReminders();
  }

  Future<void> _calculateReminders() async {
    try {
      // 1. Ambil data master imunisasi diurutkan berdasarkan usia
      final immunizationsRes = await _supabase
          .from('immunizations')
          .select()
          .order('recommended_age_months', ascending: true);

      // 2. Ambil log imunisasi yang sudah dicatat anak ini
      final logsRes = await _supabase
          .from('child_immunization_logs')
          .select('immunization_id')
          .eq('child_id', widget.childData['id']);

      final completedIds = logsRes.map((log) => log['immunization_id']).toSet();

      // 3. Hitung tanggal target berdasarkan tanggal lahir anak
      final birthDateStr = widget.childData['birth_date'];
      final DateTime birthDate = birthDateStr != null 
          ? DateTime.parse(birthDateStr) 
          : DateTime.now();

      List<Map<String, dynamic>> calculatedSchedule = [];

      for (var item in immunizationsRes) {
        int targetMonths = item['recommended_age_months'] ?? 0;
        
        // Tambahkan bulan ke tanggal lahir untuk mendapatkan estimasi tanggal vaksin
        DateTime estimatedDate = DateTime(
          birthDate.year,
          birthDate.month + targetMonths,
          birthDate.day,
        );

        bool isCompleted = completedIds.contains(item['id']);
        
        // Tentukan status jadwal relatif terhadap hari ini
        String status = 'Akan Datang';
        final now = DateTime.now();
        
        if (isCompleted) {
          status = 'Sudah Selesai';
        } else if (estimatedDate.isBefore(now)) {
          status = 'Terlewat / Segera';
        } else if (estimatedDate.difference(now).inDays <= 30) {
          status = 'Jatuh Tempo Bulan Ini';
        }

        calculatedSchedule.add({
          'vaccine_name': item['vaccine_name'],
          'recommended_age_months': targetMonths,
          'estimated_date': estimatedDate.toIso8601String().split('T')[0],
          'status': status,
          'is_completed': isCompleted,
        });
      }

      setState(() {
        _scheduleList = calculatedSchedule;
        _isLoading = false;
      });
    } catch (e) {
      print('Error calculating reminders: $e');
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Sudah Selesai':
        return Colors.green;
      case 'Jatuh Tempo Bulan Ini':
        return Colors.orange;
      case 'Terlewat / Segera':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jadwal & Pengingat: ${widget.childData['full_name']}'),
        backgroundColor: const Color(0xFF2A9D8F),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scheduleList.isEmpty
              ? const Center(child: Text('Belum ada data jadwal imunisasi.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _scheduleList.length,
                  itemBuilder: (context, index) {
                    final schedule = _scheduleList[index];
                    final statusColor = _getStatusColor(schedule['status']);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.notifications_active, color: statusColor),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    schedule['vaccine_name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF264653),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Target Usia: ${schedule['recommended_age_months']} Bulan',
                                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Estimasi: ${schedule['estimated_date']}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                schedule['status'],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}