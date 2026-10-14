import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/maternal_anc_model.dart';
import '../../models/maternal_pregnancy_model.dart';
import '../../services/maternal_child_repository.dart';
import 'add_anc_record_screen.dart';

class MaternalPregnancyScreen extends StatefulWidget {
  const MaternalPregnancyScreen({super.key});

  @override
  State<MaternalPregnancyScreen> createState() =>
      _MaternalPregnancyScreenState();
}

class _MaternalPregnancyScreenState extends State<MaternalPregnancyScreen> {
  final _repository = MaternalChildRepository();
  List<MaternalPregnancyModel> _pregnancies = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPregnancies();
  }

  Future<void> _loadPregnancies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw StateError('Sesi pengguna tidak ditemukan.');
      final records = await _repository.getPregnancies(user.id);
      if (!mounted) return;
      setState(() {
        _pregnancies = records;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addPregnancy() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi pengguna tidak ditemukan.')),
      );
      return;
    }

    DateTime hpht = DateTime.now();
    String bloodType = 'O';
    String rhesus = 'Positif';
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Tambah Data Kehamilan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month),
                title: const Text('Hari Pertama Haid Terakhir'),
                subtitle: Text(_formatDate(hpht)),
                onTap: () async {
                  final selected = await showDatePicker(
                    context: dialogContext,
                    initialDate: hpht,
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (selected != null) {
                    setDialogState(() => hpht = selected);
                  }
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: bloodType,
                decoration: const InputDecoration(labelText: 'Golongan Darah'),
                items: ['A', 'B', 'AB', 'O']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => bloodType = value);
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: rhesus,
                decoration: const InputDecoration(labelText: 'Rhesus'),
                items: ['Positif', 'Negatif']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => rhesus = value);
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Perkiraan persalinan: '
                  '${_formatDate(hpht.add(const Duration(days: 280)))}',
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      try {
                        await _repository.addPregnancy(
                          MaternalPregnancyModel(
                            id: '',
                            profileId: user.id,
                            pregnancyOrder: _pregnancies.length + 1,
                            hpht: hpht,
                            estimatedDeliveryDate: hpht.add(
                              const Duration(days: 280),
                            ),
                            bloodType: bloodType,
                            rhesus: rhesus,
                            isActive: true,
                            createdAt: DateTime.now(),
                          ),
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        await _loadPregnancies();
                      } catch (error) {
                        if (!mounted || !dialogContext.mounted) return;
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal menyimpan: $error')),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPregnancy(MaternalPregnancyModel pregnancy) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => MaternalAncRecordsScreen(pregnancy: pregnancy),
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-${date.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kehamilan dan ANC')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPregnancy,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kehamilan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Gagal memuat data kehamilan.'),
                    const SizedBox(height: 8),
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _loadPregnancies,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          : _pregnancies.isEmpty
          ? const Center(child: Text('Belum ada data kehamilan.'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: _pregnancies.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final pregnancy = _pregnancies[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.pregnant_woman),
                    ),
                    title: Text('Kehamilan ${pregnancy.pregnancyOrder}'),
                    subtitle: Text(
                      'HPHT: ${_formatDate(pregnancy.hpht)}\n'
                      'Perkiraan persalinan: '
                      '${_formatDate(pregnancy.estimatedDeliveryDate)}\n'
                      'Darah: ${pregnancy.bloodType} (${pregnancy.rhesus})',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openPregnancy(pregnancy),
                  ),
                );
              },
            ),
    );
  }
}

class MaternalAncRecordsScreen extends StatefulWidget {
  final MaternalPregnancyModel pregnancy;

  const MaternalAncRecordsScreen({super.key, required this.pregnancy});

  @override
  State<MaternalAncRecordsScreen> createState() =>
      _MaternalAncRecordsScreenState();
}

class _MaternalAncRecordsScreenState extends State<MaternalAncRecordsScreen> {
  final _repository = MaternalChildRepository();
  List<MaternalAncModel> _records = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final records = await _repository.getAncRecords(widget.pregnancy.id);
      if (!mounted) return;
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addRecord() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddAncRecordScreen(pregnancyId: widget.pregnancy.id),
      ),
    );
    if (added == true && mounted) await _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ANC Kehamilan ${widget.pregnancy.pregnancyOrder}'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecord,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Pemeriksaan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Gagal memuat pemeriksaan ANC.'),
                    const SizedBox(height: 8),
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _loadRecords,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          : _records.isEmpty
          ? const Center(child: Text('Belum ada catatan pemeriksaan ANC.'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: _records.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final record = _records[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kunjungan ${_formatDate(record.visitDate)} '
                          '• Trimester ${record.trimester}',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (record.gestationalAgeWeeks != null)
                          Text(
                            'Usia kehamilan: '
                            '${record.gestationalAgeWeeks} minggu',
                          ),
                        if (record.weightKg != null)
                          Text('Berat ibu: ${record.weightKg} kg'),
                        if (record.bloodPressure != null)
                          Text('Tekanan darah: ${record.bloodPressure}'),
                        if (record.hbLevel != null)
                          Text('Hb: ${record.hbLevel} g/dL'),
                        if (record.complaints?.isNotEmpty == true)
                          Text('Keluhan: ${record.complaints}'),
                        if (record.healthcareProviderName?.isNotEmpty == true)
                          Text(
                            'Faskes/petugas: '
                            '${record.healthcareProviderName}',
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-${date.year}';
}
