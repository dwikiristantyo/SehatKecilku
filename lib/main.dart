import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_config.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/update_password_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'SehatKecilku',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2A9D8F),
          primary: const Color(0xFF2A9D8F),
          secondary: const Color(0xFFF4A261),
          surface: const Color(0xFFF8F9FA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _processTokenHash();
  }

  Future<void> _processTokenHash() async {
    try {
      final Uri uri = Uri.base;

      String? tokenHash = uri.queryParameters['token_hash'];
      String? type = uri.queryParameters['type'];

      if ((tokenHash == null || tokenHash.isEmpty) && uri.hasFragment) {
        String fragment = uri.fragment;
        while (fragment.startsWith('/') || fragment.startsWith('?')) {
          fragment = fragment.substring(1);
        }

        final fragmentUri = Uri.parse('http://localhost?$fragment');
        tokenHash = fragmentUri.queryParameters['token_hash'];
        type = fragmentUri.queryParameters['type'];
      }

      if (tokenHash != null && tokenHash.isNotEmpty && type == 'recovery') {
        final response = await Supabase.instance.client.auth.verifyOTP(
          tokenHash: tokenHash,
          type: OtpType.recovery,
        );

        if (response.session != null && mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const UpdatePasswordScreen(),
            ),
            (route) => false,
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('Gagal memproses token hash: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _requestLocationPermission();
        });
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    if (kIsWeb ||
        !{
          TargetPlatform.android,
          TargetPlatform.iOS,
        }.contains(defaultTargetPlatform)) {
      return;
    }

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.deniedForever || !mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Izin lokasi belum aktif'),
          content: const Text(
            'Aktifkan izin lokasi di pengaturan perangkat untuk menemukan '
            'fasilitas kesehatan terdekat.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Nanti'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await Geolocator.openAppSettings();
              },
              child: const Text('Buka Pengaturan'),
            ),
          ],
        ),
      );
    } catch (error) {
      debugPrint('Gagal memeriksa izin lokasi: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2A9D8F)),
        ),
      );
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      return const DashboardScreen();
    }

    return const LoginScreen();
  }
}
