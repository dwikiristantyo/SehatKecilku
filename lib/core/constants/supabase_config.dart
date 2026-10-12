import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://gabvmyhqfvwcmtgicfls.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdhYnZteWhxZnZ3Y210Z2ljZmxzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE0MjUzNjUsImV4cCI6MjEwNzAwMTM2NX0.00RI1TNwIZOqFW_NX4gMYKkwXtAbQAco9k9BYLOXM9U'; // Masukkan anon key Supabase kamu di sini

  static SupabaseClient get client => Supabase.instance.client;
}