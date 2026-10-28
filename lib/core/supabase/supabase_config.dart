import 'package:supabase_flutter/supabase_flutter.dart';

/// Compile-time Supabase connection settings. The publishable key is not a
/// secret; authorization is enforced by database and storage policies.
class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured =>
      url.startsWith('https://') && publishableKey.isNotEmpty;

  static SupabaseClient? get clientOrNull =>
      isConfigured ? Supabase.instance.client : null;
}
