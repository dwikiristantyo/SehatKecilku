import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _parentEmail = '-';
  String _relationship = 'mother';
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw StateError('Sesi pengguna tidak ditemukan.');

      final response = await _supabase
          .from('profiles')
          .select('full_name, phone_number, relationship')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;
      _parentEmail = user.email ?? '-';
      if (response != null) {
        _nameController.text = response['full_name']?.toString() ?? '';
        _phoneController.text = response['phone_number']?.toString() ?? '';
        final relationship = response['relationship']?.toString();
        if (['mother', 'father', 'guardian'].contains(relationship)) {
          _relationship = relationship!;
        }
      }
      setState(() => _isLoading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi pengguna tidak ditemukan.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _supabase
          .from('profiles')
          .update({
            'full_name': _nameController.text.trim(),
            'phone_number': _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            'relationship': _relationship,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui profil: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleLogout() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        backgroundColor: const Color(0xFF2A9D8F),
        foregroundColor: Colors.white,
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
                    const Text('Gagal memuat profil.'),
                    const SizedBox(height: 8),
                    Text(_loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        setState(() => _isLoading = true);
                        _loadProfileData();
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const CircleAvatar(
                      radius: 46,
                      backgroundColor: Color(0xFF2A9D8F),
                      child: Icon(Icons.person, size: 54, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Nama lengkap wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _parentEmail,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Email Akun',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Telepon',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _relationship,
                      decoration: const InputDecoration(
                        labelText: 'Hubungan dengan Anak',
                        prefixIcon: Icon(Icons.family_restroom),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'mother', child: Text('Ibu')),
                        DropdownMenuItem(value: 'father', child: Text('Ayah')),
                        DropdownMenuItem(
                          value: 'guardian',
                          child: Text('Wali'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _relationship = value);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _saveProfile,
                      icon: _isSaving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Profil'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Keluar Akun'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
