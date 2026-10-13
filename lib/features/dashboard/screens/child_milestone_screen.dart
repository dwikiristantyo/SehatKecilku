import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChildMilestoneScreen extends StatefulWidget {
  final Map<String, dynamic> childData;

  const ChildMilestoneScreen({super.key, required this.childData});

  @override
  State<ChildMilestoneScreen> createState() => _ChildMilestoneScreenState();
}

class _ChildMilestoneScreenState extends State<ChildMilestoneScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _allMilestones = [];
  List<Map<String, dynamic>> _childLogs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMilestoneData();
  }

  Future<void> _fetchMilestoneData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 1. Ambil data master milestones
      final milestonesRes = await _supabase
          .from('milestones')
          .select()
          .order('min_age_months', ascending: true);

      // 2. Ambil log milestone anak
      final logsRes = await _supabase
          .from('child_milestone_logs')
          .select()
          .eq('child_id', widget.childData['id']);

      setState(() {
        _allMilestones = List<Map<String, dynamic>>.from(milestonesRes);
        _childLogs = List<Map<String, dynamic>>.from(logsRes);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching milestones: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleMilestoneStatus(Map<String, dynamic> milestone, Map<String, dynamic>? existingLog) async {
    try {
      if (existingLog != null && existingLog.isNotEmpty) {
        // Hapus log jika checkbox dilepas
        await _supabase
            .from('child_milestone_logs')
            .delete()
            .eq('id', existingLog['id']);
      } else {
        // Simpan log hanya dengan child_id dan milestone_id
        await _supabase.from('child_milestone_logs').insert({
          'child_id': widget.childData['id'],
          'milestone_id': milestone['id'],
        });
      }

      _fetchMilestoneData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Milestone: ${widget.childData['full_name']}'),
        backgroundColor: const Color(0xFF2A9D8F),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Terjadi kesalahan memuat data:\n$_errorMessage',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : _allMilestones.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada data master milestone di database.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _allMilestones.length,
                      itemBuilder: (context, index) {
                        final item = _allMilestones[index];
                        
                        final existingLog = _childLogs.firstWhere(
                          (log) => log['milestone_id'] == item['id'],
                          orElse: () => {},
                        );

                        final bool isAchieved = existingLog.isNotEmpty;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: CheckboxListTile(
                            activeColor: const Color(0xFF2A9D8F),
                            title: Text(
                              item['question_text'] ?? '-',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: isAchieved ? TextDecoration.lineThrough : null,
                                color: isAchieved ? Colors.grey : Colors.black87,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                'Rentang Usia: ${item['min_age_months']} - ${item['max_age_months']} Bulan${item['category'] != null ? ' • Kategori: ${item['category']}' : ''}',
                                style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                              ),
                            ),
                            value: isAchieved,
                            onChanged: (bool? value) {
                              _toggleMilestoneStatus(item, isAchieved ? existingLog : null);
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}