import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const config = AppConfig.fromEnvironment();

  await Firebase.initializeApp();

  if (config.hasBackendConfig) {
    await Supabase.initialize(
      url: config.backendUrl,
      anonKey: config.backendPublicKey,
    );

    await PushNotificationService().initialize();
  }

  runApp(DiscoveryPetApp(config: config));
}
