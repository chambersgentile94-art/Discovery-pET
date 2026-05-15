import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const config = AppConfig.fromEnvironment();

  if (config.hasBackendConfig) {
    await Supabase.initialize(
      url: config.backendUrl,
      anonKey: config.backendPublicKey,
    );
  }

  runApp(DiscoveryPetApp(config: config));
}
