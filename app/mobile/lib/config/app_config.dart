class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.googleMapsApiKey,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String googleMapsApiKey;

  bool get hasSupabaseConfig {
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseUrl.contains('TU-PROYECTO') &&
        !supabaseAnonKey.contains('TU_PUBLIC_ANON_KEY');
  }

  bool get hasGoogleMapsConfig {
    return googleMapsApiKey.isNotEmpty &&
        !googleMapsApiKey.contains('TU_GOOGLE_MAPS_API_KEY');
  }

  static const empty = AppConfig(
    supabaseUrl: '',
    supabaseAnonKey: '',
    googleMapsApiKey: '',
  );
}
