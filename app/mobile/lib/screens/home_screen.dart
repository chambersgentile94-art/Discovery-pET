import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/supabase_service.dart';
import '../widgets/home_action_card.dart';
import 'adoption_requests_screen.dart';
import 'adoption_screen.dart';
import 'alert_preferences_screen.dart';
import 'map_screen.dart';
import 'moderation_screen.dart';
import 'my_reports_screen.dart';
import 'profile_screen.dart';
import 'report_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<UserProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = SupabaseService().fetchCurrentProfile();
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _profileFuture = SupabaseService().fetchCurrentProfile();
    });
    await _profileFuture;
  }

  List<HomeActionCard> _buildCards(UserProfile? profile) {
    final cards = [
      HomeActionCard(
        icon: Icons.location_on,
        title: 'Ver mapa',
        description: 'Consultar mascotas perdidas, vistas o resguardadas cerca.',
        onTap: () => Navigator.pushNamed(context, MapScreen.routeName),
      ),
      HomeActionCard(
        icon: Icons.add_location_alt,
        title: 'Reportar animal',
        description: 'Publicar una mascota perdida, abandonada o vista en la calle.',
        onTap: () => Navigator.pushNamed(context, ReportFormScreen.routeName),
      ),
      HomeActionCard(
        icon: Icons.notifications_active,
        title: 'Alertas por zona',
        description: 'Elegir radio, ubicación y categorías para futuras notificaciones.',
        onTap: () => Navigator.pushNamed(context, AlertPreferencesScreen.routeName),
      ),
      HomeActionCard(
        icon: Icons.assignment_ind,
        title: 'Mis reportes',
        description: 'Revisar, cerrar o dar seguimiento a los casos que publicaste.',
        onTap: () => Navigator.pushNamed(context, MyReportsScreen.routeName),
      ),
      HomeActionCard(
        icon: Icons.favorite,
        title: 'Adopciones',
        description: 'Ver animales disponibles para adoptar.',
        onTap: () => Navigator.pushNamed(context, AdoptionScreen.routeName),
      ),
      HomeActionCard(
        icon: Icons.mark_email_read,
        title: 'Solicitudes de adopción',
        description: 'Revisar interesados en adoptar animales publicados por vos.',
        onTap: () => Navigator.pushNamed(context, AdoptionRequestsScreen.routeName),
      ),
      HomeActionCard(
        icon: Icons.person,
        title: 'Mi perfil',
        description: 'Gestionar usuario, contacto y participación como voluntario.',
        onTap: () async {
          await Navigator.pushNamed(context, ProfileScreen.routeName);
          if (!mounted) return;
          await _refreshProfile();
        },
      ),
    ];

    if (profile?.isAdmin == true) {
      cards.insert(
        cards.length - 1,
        HomeActionCard(
          icon: Icons.admin_panel_settings,
          title: 'Moderación',
          description: 'Revisar denuncias de publicaciones y ocultar reportes inválidos.',
          onTap: () => Navigator.pushNamed(context, ModerationScreen.routeName),
        ),
      );
    }

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discovery-pET'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _refreshProfile,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<UserProfile?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            final cards = _buildCards(snapshot.data);

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🐾 Ayudá a encontrar, rescatar o adoptar mascotas',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Marcá en el mapa animales perdidos, abandonados o vistos en la calle. '
                        'La comunidad puede colaborar y dar seguimiento a cada caso.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(),
                if (snapshot.data?.isAdmin == true)
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.verified_user),
                      title: Text('Modo administrador'),
                      subtitle: Text('Tenés habilitado el acceso a moderación.'),
                    ),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Acciones principales',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...cards,
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, ReportFormScreen.routeName),
        icon: const Icon(Icons.add),
        label: const Text('Reportar'),
      ),
    );
  }
}
