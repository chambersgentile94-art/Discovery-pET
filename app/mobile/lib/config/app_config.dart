class AppConfig {
  const AppConfig({
    required this.backendUrl,
    required this.backendPublicKey,
    required this.mapsKey,
  });

  const AppConfig.fromEnvironment()
      : backendUrl = const String.fromEnvironment('DP_BACKEND_URL'),
        backendPublicKey = const String.fromEnvironment('DP_BACKEND_PUBLIC_KEY'),
        mapsKey = const String.fromEnvironment('DP_MAPS_KEY');

  final String backendUrl;
  final String backendPublicKey;
  final String mapsKey;

  bool get hasBackendConfig {
    return backendUrl.isNotEmpty && backendPublicKey.isNotEmpty;
  }

  bool get hasMapsConfig {
    return mapsKey.isNotEmpty;
  }

  static const empty = AppConfig(
    backendUrl: '',
    backendPublicKey: '',
    mapsKey: '',
  );
}
