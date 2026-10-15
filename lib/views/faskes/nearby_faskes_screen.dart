import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class NearbyFaskesScreen extends StatefulWidget {
  const NearbyFaskesScreen({Key? key}) : super(key: key);

  @override
  _NearbyFaskesScreenState createState() => _NearbyFaskesScreenState();
}

class _NearbyFaskesScreenState extends State<NearbyFaskesScreen> {
  bool _isLoading = true;
  String _locationMessage = "Mendeteksi lokasi Anda...";
  Position? _currentPosition;

  // Mock data faskes/RSIA terdekat (bisa diganti dengan data dari Supabase/Google Places API)
  final List<Map<String, dynamic>> _faskesList = [
    {
      "name": "[RSUD Kebayoran Baru](http://googleusercontent.com/map_location_reference/0)",
      "address": "Jl. Abdul Majid Raya No.28, Cipete Utara, Jakarta Selatan",
      "distance": "900 m",
      "phone": "+62 21 22774429",
      "status": "Buka 24 Jam",
    },
    {
      "name": "[Brawijaya Hospital Antasari](http://googleusercontent.com/map_location_reference/1)",
      "address": "Jl. Taman Brawijaya No.1, Cipete Utara, Jakarta Selatan",
      "distance": "1.6 km",
      "phone": "+62 150160",
      "status": "Buka 24 Jam",
    },
    {
      "name": "[Rumah Sakit Ibu dan Anak Brawijaya](http://googleusercontent.com/map_location_reference/2)",
      "address": "Jl. Taman Brawijaya No.1, Cipete Utara, Jakarta Selatan",
      "distance": "1.7 km",
      "phone": "+62 150160",
      "status": "Buka 24 Jam",
    },
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // Fungsi untuk mendapatkan koordinat GPS perangkat
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek apakah Layanan Lokasi aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoading = false;
        _locationMessage = "Layanan GPS/Lokasi tidak aktif.";
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = false;
          _locationMessage = "Izin akses lokasi ditolak oleh pengguna.";
        });
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoading = false;
        _locationMessage = "Izin lokasi ditolak secara permanen. Ubah di pengaturan perangkat.";
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _isLoading = false;
        _locationMessage = "Lokasi terdeteksi: ${position.latitude}, ${position.longitude}";
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _locationMessage = "Gagal Mendapatkan Koordinat GPS: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Faskes & RSIA Terdekat'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Status GPS
          Container(
            width: double.infinity,
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locationMessage,
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Daftar Rumah Sakit & Puskesmas Rujukan:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // Daftar Faskes
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _faskesList.length,
                    itemBuilder: (context, index) {
                      final faskes = _faskesList[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      faskes['name'],
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      faskes['distance'],
                                      style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Text(
                                faskes['address'],
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                              ),
                              SizedBox(height: 8),
                              Divider(),
                              SizedBox(height: 4),
                              // Informasi Kontak & Status (Hanya Menampilkan Teks, Tidak Ada Aksi Tombol Panggil)
                              Row(
                                children: [
                                  Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                                  SizedBox(width: 6),
                                  Text(
                                    'Kontak Info: ${faskes['phone']}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                                  ),
                                  Spacer(),
                                  Text(
                                    faskes['status'],
                                    style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}