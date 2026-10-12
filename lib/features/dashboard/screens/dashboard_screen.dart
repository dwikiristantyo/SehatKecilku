import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/screens/login_screen.dart';
import 'add_child_screen.dart';
import 'child_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  List<Map<String, dynamic>> _childrenList = [];
  bool _isLoading = true;
  String _parentName = 'Orang Tua';

  @override
  void initState() {
    super.initState();
    _loadUserDataAndChildren();
  }

  Future<void> _loadUserDataAndChildren() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      // Ambil nama profil orang tua dari tabel profiles
      final profileRes = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();

      if (profileRes != null && profileRes['full_name'] != null) {
        _parentName = profileRes['full_name'];
      }

      // Ambil daftar anak yang terhubung dengan parent_id (profiles.id)
      final childrenRes = await _client
          .from('children')
          .select()
          .eq('parent_id', user.id);

      setState(() {
        _childrenList = List<Map<String, dynamic>>.from(childrenRes);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await _client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
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
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang,',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  Text(
                    _parentName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF264653),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Daftar Anak',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF264653),
                        ),
                      ),
                      if (_childrenList.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddChildScreen(),
                              ),
                            );
                            if (result == true) {
                              _loadUserDataAndChildren();
                            }
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tambah Anak'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A9D8F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _childrenList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.child_care,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 12),
                                const Text(
                                  'Belum ada data anak yang terdaftar.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AddChildScreen(),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadUserDataAndChildren();
                                    }
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Tambah Data Anak'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2A9D8F),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _childrenList.length,
                            itemBuilder: (context, index) {
                              final child = _childrenList[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF2A9D8F)
                                        .withOpacity(0.2),
                                    child: const Icon(Icons.face,
                                        color: Color(0xFF2A9D8F)),
                                  ),
                                  title: Text(
                                    child['full_name'] ?? 'Tanpa Nama',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                      'Jenis Kelamin: ${child['gender']} | Lahir: ${child['birth_date']}'),
                                  trailing: const Icon(Icons.arrow_forward_ios,
                                      size: 16),
                                  onTap: () {
                                    Navigator.push(
                                       context,
                                       MaterialPageRoute(
                                       builder: (context) => ChildDetailScreen(childData: child),
                                        ),
                                 );
                                  },
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