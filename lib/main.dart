import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_config.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart'; // Pastikan import ini ada

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase menggunakan konstanta dari SupabaseConfig
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
      title: 'SehatKecilku',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2A9D8F), // Primary Teal
          primary: const Color(0xFF2A9D8F),
          secondary: const Color(0xFFF4A261), // Soft Orange
          surface: const Color(0xFFF8F9FA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        // Tipografi utama Plus Jakarta Sans
        //textTheme: GoogleFonts.plusJakartaSansTextTheme(
          //ThemeData.light().textTheme,
        //),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Memeriksa status sesi pengguna di Supabase
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // Langsung arahkan ke DashboardScreen yang sebenarnya jika sesi aktif
      return const DashboardScreen();
    }

    // Arahkan ke LoginScreen jika belum ada sesi login
    return const LoginScreen();
  }
}