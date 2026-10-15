import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/screens/login_screen.dart';
import 'add_child_screen.dart';
import 'child_immunization_screen.dart';
import 'child_milestone_screen.dart';
import 'child_reminder_screen.dart';
import '../../../screen/maternal/maternal_pregnancy_screen.dart';
import 'profile_screen.dart';
import 'growth_standards_chart.dart';
import '../child_display.dart';
import 'health_articles_section.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _children = [];
  bool _isLoading = true;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw StateError('Sesi pengguna tidak ditemukan.');
      }

      final response = await _supabase
          .from('children')
          .select()
          .eq('parent_id', user.id);

      if (!mounted) return;
      setState(() {
        _children = List<Map<String, dynamic>>.from(response);
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

  Future<void> _addChild() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddChildScreen()),
    );
    if (added == true) await _loadChildren();
  }

  Future<void> _signOut() async {
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
        title: const Text('SehatKecilku Dashboard'),
        backgroundColor: const Color(0xFF2A9D8F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MaternalPregnancyScreen(),
                ),
              );
            },
            icon: const Icon(Icons.pregnant_woman),
            tooltip: 'Kehamilan dan ANC',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profil Pengguna',
          ),
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_loadError != null) ...[
                  const Text('Gagal memuat data anak.'),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: _loadChildren,
                      child: const Text('Coba lagi'),
                    ),
                  ),
                ] else if (_children.isEmpty) ...[
                  const Text(
                    'Daftar Anak',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Belum ada data anak.'),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: _addChild,
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Anak'),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Daftar Anak',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._children.map((child) {
                    final style = childDisplayStyle(child['gender']);
                    final birthDate = child['birth_date'];

                    return Card(
                      color: style.backgroundColor,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: style.accentColor.withValues(
                            alpha: 0.14,
                          ),
                          child: Icon(style.icon, color: style.accentColor),
                        ),
                        title: Text(
                          child['full_name']?.toString() ??
                              'Nama tidak tersedia',
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tanggal lahir: ${formatChildBirthDate(birthDate)}',
                            ),
                            Text(formatChildAge(birthDate)),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ChildDetailScreen(childData: child),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _addChild,
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Anak'),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const HealthArticlesSection(),
              ],
            ),
    );
  }
}

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

  // Dialog untuk Tambah atau Edit Data Pertumbuhan
  void _showGrowthDialog({Map<String, dynamic>? recordToEdit}) {
    final isEditing = recordToEdit != null;
    final weightController = TextEditingController(
      text: isEditing ? recordToEdit['weight_kg'].toString() : '',
    );
    final heightController = TextEditingController(
      text: isEditing ? recordToEdit['height_cm'].toString() : '',
    );
    final headController = TextEditingController(
      text: isEditing && recordToEdit['head_circumference_cm'] != null
          ? recordToEdit['head_circumference_cm'].toString()
          : '',
    );
    final placeController = TextEditingController(
      text: isEditing ? (recordToEdit['healthcare_provider_name'] ?? '') : '',
    );
    final officerController = TextEditingController(
      text: isEditing ? (recordToEdit['healthcare_provider_type'] ?? '') : '',
    );

    DateTime selectedDate = isEditing && recordToEdit['recorded_at'] != null
        ? DateTime.parse(recordToEdit['recorded_at'])
        : DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                isEditing
                    ? 'Edit Catatan Pertumbuhan'
                    : 'Tambah Catatan Pertumbuhan',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Berat Badan (kg)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: heightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Tinggi/Panjang Badan (cm)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: headController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Lingkar Kepala (cm - Opsional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: placeController,
                      decoration: InputDecoration(
                        labelText: 'Tempat (Puskesmas/Klinik/RS/Posyandu)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: officerController,
                      decoration: InputDecoration(
                        labelText: 'Petugas In Charge (Dokter/Bidan/Petugas)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A9D8F),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (weightController.text.isEmpty ||
                        heightController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Berat dan Tinggi badan wajib diisi'),
                        ),
                      );
                      return;
                    }

                    try {
                      final dataPayload = {
                        'child_id': widget.childData['id'],
                        'recorded_at':
                            "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                        'weight_kg': double.parse(weightController.text),
                        'height_cm': double.parse(heightController.text),
                        'head_circumference_cm': headController.text.isNotEmpty
                            ? double.parse(headController.text)
                            : null,
                        'healthcare_provider_name':
                            placeController.text.trim().isNotEmpty
                            ? placeController.text.trim()
                            : null,
                        'healthcare_provider_type':
                            officerController.text.trim().isNotEmpty
                            ? officerController.text.trim()
                            : null,
                      };

                      if (isEditing) {
                        await _supabase
                            .from('growth_records')
                            .update(dataPayload)
                            .eq('id', recordToEdit['id']);
                      } else {
                        await _supabase
                            .from('growth_records')
                            .insert(dataPayload);
                      }

                      if (mounted) {
                        Navigator.pop(context);
                        _loadGrowthRecords();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEditing
                                  ? 'Catatan pertumbuhan berhasil diperbarui!'
                                  : 'Catatan pertumbuhan berhasil ditambahkan!',
                            ),
                          ),
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
                  child: Text(isEditing ? 'Perbarui' : 'Simpan'),
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
    return GrowthStandardsChart(
      childName: widget.childData['full_name']?.toString() ?? 'Anak',
      childGender: widget.childData['gender']?.toString() ?? '',
      childBirthDate: widget.childData['birth_date']?.toString() ?? '',
      growthRecords: _growthRecords,
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.childData;
    final style = childDisplayStyle(child['gender']);
    final birthDate = child['birth_date'];

    return Scaffold(
      appBar: AppBar(
        title: Text(child['full_name'] ?? 'Detail Anak'),
        backgroundColor: const Color(0xFF2A9D8F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        // Membungkus seluruh halaman agar bisa di-scroll dengan mulus
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kartu Profil Anak
            Card(
              color: style.backgroundColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: style.accentColor.withValues(
                        alpha: 0.14,
                      ),
                      child: Icon(
                        style.icon,
                        size: 36,
                        color: style.accentColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child['full_name'] ?? '-',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Jenis Kelamin: ${style.genderLabel}'),
                          Text(
                            'Tanggal Lahir: ${formatChildBirthDate(birthDate)}',
                          ),
                          Text(formatChildAge(birthDate)),
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
                          builder: (context) => ChildImmunizationScreen(
                            childData: widget.childData,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.vaccines, size: 16),
                    label: const Text('Imunisasi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF264653),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                          builder: (context) =>
                              ChildMilestoneScreen(childData: widget.childData),
                        ),
                      );
                    },
                    icon: const Icon(Icons.emoji_events, size: 16),
                    label: const Text('Milestone'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE76F51),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                          builder: (context) =>
                              ChildReminderScreen(childData: widget.childData),
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications_active, size: 16),
                    label: const Text('Jadwal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A9D8F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tampilkan Grafik Berat Badan Jika Ada Data
            _buildWeightChart(),
            const SizedBox(height: 20),

            // Header Riwayat Pertumbuhan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat Pertumbuhan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF264653),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showGrowthDialog(),
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

            // Daftar Riwayat Pertumbuhan Menggunakan ListView.builder dengan shrinkWrap
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _growthRecords.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'Belum ada catatan pertumbuhan.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _growthRecords.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final record = _growthRecords[index];
                      final place = record['healthcare_provider_name'];
                      final officer = record['healthcare_provider_type'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tanggal: ${record['recorded_at']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF264653),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (place != null &&
                                          place.toString().isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2A9D8F)
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            place,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF2A9D8F),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 4),
                                      // Tombol Edit
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: Color(0xFF2A9D8F),
                                        ),
                                        onPressed: () => _showGrowthDialog(
                                          recordToEdit: record,
                                        ),
                                        tooltip: 'Edit Catatan',
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Berat: ${record['weight_kg']} kg | Tinggi: ${record['height_cm']} cm${record['head_circumference_cm'] != null ? ' | LK: ${record['head_circumference_cm']} cm' : ''}',
                              ),
                              if (officer != null &&
                                  officer.toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Petugas: $officer',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
