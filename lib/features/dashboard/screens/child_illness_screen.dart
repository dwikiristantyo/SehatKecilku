import 'package:flutter/material.dart';

import '../../../models/child_illness_model.dart';
import '../../../services/maternal_child_repository.dart';

class ChildIllnessScreen extends StatefulWidget {
  final String childId;

  const ChildIllnessScreen({super.key, required this.childId});

  @override
  State<ChildIllnessScreen> createState() => _ChildIllnessScreenState();
}

class _ChildIllnessScreenState extends State<ChildIllnessScreen> {
  final _repository = MaternalChildRepository();
  List<ChildIllnessModel> _records = [];
  bool _isLoading = true;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final records = await _repository.getChildIllnesses(widget.childId);
      if (!mounted) return;
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddRecordDialog() async {
    final formKey = GlobalKey<FormState>();
    final illnessController = TextEditingController();
    final symptomsController = TextEditingController();
    final treatmentController = TextEditingController();
    final notesController = TextEditingController();
    var recordedDate = DateTime.now();
    var isReferred = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Catat Riwayat Sakit'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: illnessController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Penyakit atau keluhan',
                        hintText: 'Contoh: demam, batuk, diare',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Isi penyakit atau keluhan'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: recordedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => recordedDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_formatDate(recordedDate)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: symptomsController,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Gejala',
                        hintText: 'Pisahkan beberapa gejala dengan koma',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: treatmentController,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Penanganan atau obat',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Dirujuk ke rumah sakit'),
                      value: isReferred,
                      onChanged: (value) =>
                          setDialogState(() => isReferred = value ?? false),
                    ),
                    TextFormField(
                      controller: notesController,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Catatan tambahan',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final record = ChildIllnessModel(
                    id: '',
                    childId: widget.childId,
                    recordedDate: recordedDate,
                    illnessType: illnessController.text.trim(),
                    symptoms: symptomsController.text
                        .split(RegExp(r'[,;\n]'))
                        .map((symptom) => symptom.trim())
                        .where((symptom) => symptom.isNotEmpty)
                        .toList(),
                    treatmentGiven: _nullableText(treatmentController.text),
                    isReferredToHospital: isReferred,
                    notes: _nullableText(notesController.text),
                    createdAt: DateTime.now(),
                  );
                  await _repository.addChildIllness(record);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, true);
                  }
                } catch (error) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menyimpan catatan: $error'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    illnessController.dispose();
    symptomsController.dispose();
    treatmentController.dispose();
    notesController.dispose();

    if (saved == true && mounted) {
      await _loadRecords();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Riwayat sakit berhasil disimpan.')),
        );
      }
    }
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Sakit Anak')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRecordDialog,
        icon: const Icon(Icons.add),
        label: const Text('Catat Sakit'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Riwayat sakit gagal dimuat.'),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _loadRecords,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            )
          : _records.isEmpty
          ? const Center(child: Text('Belum ada riwayat sakit anak.'))
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.medical_services_outlined,
                              color: Color(0xFF2A9D8F),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                record.illnessType,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              _formatDate(record.recordedDate),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        if (record.symptoms.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text('Gejala: ${record.symptoms.join(', ')}'),
                        ],
                        if (record.treatmentGiven != null) ...[
                          const SizedBox(height: 6),
                          Text('Penanganan: ${record.treatmentGiven}'),
                        ],
                        if (record.notes != null) ...[
                          const SizedBox(height: 6),
                          Text('Catatan: ${record.notes}'),
                        ],
                        if (record.isReferredToHospital) ...[
                          const SizedBox(height: 10),
                          const Chip(
                            avatar: Icon(
                              Icons.local_hospital_outlined,
                              size: 18,
                            ),
                            label: Text('Dirujuk ke rumah sakit'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
