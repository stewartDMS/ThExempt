class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '', // Set at build time via --dart-define=SUPABASE_URL=...
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '', // Set at build time via --dart-define=SUPABASE_ANON_KEY=...
  );
}
