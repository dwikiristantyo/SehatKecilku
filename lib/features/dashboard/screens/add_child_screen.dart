import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _birthWeightController = TextEditingController();
  final _birthLengthController = TextEditingController();
  final _headCircumferenceController = TextEditingController();

  String _selectedGender = 'male';
  DateTime? _selectedBirthDate;
  bool _isLoading = false;

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2A9D8F),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _saveChildData() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih tanggal lahir anak')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Sesi pengguna tidak ditemukan.');

      // Menyimpan data ke tabel children sesuai skema database Supabase kamu
      await _supabase.from('children').insert({
        'parent_id': user.id,
        'full_name': _nameController.text.trim(),
        'gender': _selectedGender,
        'birth_date': _selectedBirthDate!.toIso8601String().split('T')[0],
        'birth_weight_kg': _birthWeightController.text.isNotEmpty 
            ? double.parse(_birthWeightController.text) 
            : null,
        'birth_length_cm': _birthLengthController.text.isNotEmpty 
            ? double.parse(_birthLengthController.text) 
            : null,
        'head_circumference_cm': _headCircumferenceController.text.isNotEmpty 
            ? double.parse(_headCircumferenceController.text) 
            : null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data anak berhasil ditambahkan!')),
        );
        Navigator.pop(context, true); // Kembali ke dashboard dengan membawa status refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: ${e.toString()}'))
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Data Anak'),
        backgroundColor: const Color(0xFF2A9D8F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap Anak',
                  prefixIcon: const Icon(Icons.child_care),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty 
                    ? 'Nama anak wajib diisi' 
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'Jenis Kelamin',
                  prefixIcon: const Icon(Icons.wc),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Laki-laki')),
                  DropdownMenuItem(value: 'female', child: Text('Perempuan')),
                ],
                onChanged: (value) {
                  setState(() => _selectedGender = value!);
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectBirthDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Tanggal Lahir',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selectedBirthDate == null
                        ? 'Pilih Tanggal Lahir'
                        : '${_selectedBirthDate!.day}-${_selectedBirthDate!.month}-${_selectedBirthDate!.year}',
                    style: TextStyle(
                      color: _selectedBirthDate == null ? Colors.grey[600] : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _birthWeightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Berat Lahir (kg)',
                        prefixIcon: const Icon(Icons.monitor_weight_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _birthLengthController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Panjang Lahir (cm)',
                        prefixIcon: const Icon(Icons.height),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _headCircumferenceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Lingkar Kepala Lahir (cm - Opsional)',
                  prefixIcon: const Icon(Icons.circle_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveChildData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A9D8F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Simpan Data Anak',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}