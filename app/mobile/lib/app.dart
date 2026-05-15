import 'package:flutter/material.dart';

import 'screens/adoption_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/report_form_screen.dart';

class DiscoveryPetApp extends StatelessWidget {
  const DiscoveryPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Discovery-pET',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B2CBF),
        ),
        useMaterial3: true,
      ),
      initialRoute: HomeScreen.routeName,
      routes: {
        HomeScreen.routeName: (_) => const HomeScreen(),
        MapScreen.routeName: (_) => const MapScreen(),
        ReportFormScreen.routeName: (_) => const ReportFormScreen(),
        AdoptionScreen.routeName: (_) => const AdoptionScreen(),
        ProfileScreen.routeName: (_) => const ProfileScreen(),
      },
    );
  }
}
