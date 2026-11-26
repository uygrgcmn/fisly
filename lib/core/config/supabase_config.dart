import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  static Future<void> initialize() async {
    final hasUrl = url.isNotEmpty;
    final hasKey = publishableKey.isNotEmpty;
    if (!hasUrl && !hasKey) return;
    if (!hasUrl || !hasKey) {
      throw StateError(
        'Set both SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY, or leave both empty.',
      );
    }

    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }
}
