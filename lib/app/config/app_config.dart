class AppConfig {
  AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ubkecitvuupauwiajxli.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVia2VjaXR2dXVwYXV3aWFqeGxpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4OTc1ODUsImV4cCI6MjEwNzQ3MzU4NX0.dlMZjySJtk-9wFQV04CcSmIgq505Ewf_JnnYoV3LCrE',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: supabaseAnonKey,
  );

  static const String supabaseStorageBucket = String.fromEnvironment(
    'SUPABASE_STORAGE_BUCKET',
    defaultValue: 'learning-docs',
  );

  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'your-project-id.appspot.com',
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.startsWith('https://') && supabasePublishableKey.isNotEmpty;

  static bool get isConfigured => isSupabaseConfigured;
}
