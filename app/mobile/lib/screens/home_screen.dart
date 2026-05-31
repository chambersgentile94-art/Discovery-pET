import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../services/supabase_service.dart';
import '../widgets/home_action_card.dart';
import 'adoption_requests_screen.dart';
import 'adoption_screen.dart';
import 'alert_events_screen.dart';
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
  late Future<int> _pendingAlertsFuture;
  RealtimeChannel? _alertsChannel;
  int _pendingAlertsCount = 0;

  @override
  void initState() {
    super.initState();
    _profileFuture = SupabaseService().fetchCurrentProfile();
    _pendingAlertsFuture = _loadPendingAlerts();
    _subscribeToAlertEvents();
  }

  @override
  void dispose() {
    final channel = _alertsChannel;
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
    }
    super.dispose();
  }

  Future<int> _loadPendingAlerts() async {
    final count = await SupabaseService().fetchCurrentUserPendingAlertCount();
    if (mounted) {
      setState(() {
        _pendingAlertsCount = count;
      });
    }
    return count;
  }

  void _subscribeToAlertEvents() {
    final oldChannel = _alertsChannel;
    if (oldChannel != null) {
      Supabase.instance.client.removeChannel(oldChannel);
      _alertsChannel = null;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _alertsChannel = Supabase.instance.client
        .channel('home-alert-events-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'alert_events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (_) {
            if (!mounted) return;
            _refreshPendingAlertCount();
          },
        )
        .subscribe();
  }

  Future<void> _refreshPendingAlertCount() async {
    final nextPendingAlertsFuture = _loadPendingAlerts();
    setState(() {
      _pendingAlertsFuture = nextPendingAlertsFuture;
    });
    await nextPendingAlertsFuture;
  }

  Future<void> _refreshHome() async {
    final nextProfileFuture = SupabaseService().fetchCurrentProfile();
    final nextPendingAlertsFuture = _loadPendingAlerts();

    setState(() {
      _profileFuture = nextProfileFuture;
      _pendingAlertsFuture = nextPendingAlertsFuture;
    });

    _subscribeToAlertEvents();

    await Future.wait([
      nextProfileFuture,
      nextPendingAlertsFuture,
    ]);
  }

  Future<void> _refreshProfile() => _refreshHome();

  Future<void> _openAlertEvents() async {
    await Navigator.pushNamed(context, AlertEventsScreen.routeName);
    if (!mounted) return;
    await _refreshHome();
  }

  List<HomeActionCard> _buildCards(UserProfile? profile, int pendingAlerts) {
    final alertDescription = pendingAlerts > 0
        ? '$pendingAlerts alerta(s) pendiente(s). Revisá reportes nuevos en tu zona.'
        : 'Sin alertas pendientes. Ver reportes nuevos que coinciden con tu zona.';

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
        onTap: () async {
          await Navigator.pushNamed(context, ReportFormScreen.routeName);
          if (!mounted) return;
          await _refreshHome();
        },
      ),
      HomeActionCard(
        icon: pendingAlerts > 0 ? Icons.notifications_active : Icons.notifications_none,
        title: pendingAlerts > 0 ? 'Mis alertas · $pendingAlerts' : 'Mis alertas',
        description: alertDescription,
        onTap: _openAlertEvents,
      ),
      HomeActionCard(
        icon: Icons.settings_applications,
        title: 'Configurar alertas',
        description: 'Elegir radio, ubicación y categorías para futuras notificaciones.',
        onTap: () async {
          await Navigator.pushNamed(context, AlertPreferencesScreen.routeName);
          if (!mounted) return;
          await _refreshHome();
        },
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
          await _refreshHome();
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

  Widget _buildAlertSummaryCard(int pendingAlerts) {
    if (Supabase.instance.client.auth.currentUser == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: ListTile(
        leading: Icon(
          pendingAlerts > 0 ? Icons.notifications_active : Icons.notifications_none,
        ),
        title: Text(
          pendingAlerts > 0
              ? '$pendingAlerts alerta(s) pendiente(s)'
              : 'Sin alertas pendientes',
        ),
        subtitle: const Text('Entrá a Mis alertas para ver o marcar novedades.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: _openAlertEvents,
      ),
    );
  }

  Widget _buildAlertActionButton() {
    return IconButton(
      onPressed: _openAlertEvents,
      tooltip: 'Mis alertas',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            _pendingAlertsCount > 0
                ? Icons.notifications_active
                : Icons.notifications_none,
          ),
          if (_pendingAlertsCount > 0)
            Positioned(
              right: -7,
              top: -7,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(20),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  _pendingAlertsCount > 99 ? '99+' : '$_pendingAlertsCount',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discovery-pET'),
        centerTitle: false,
        actions: [
          _buildAlertActionButton(),
          IconButton(
            onPressed: _refreshHome,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait([
            _profileFuture,
            _pendingAlertsFuture,
          ]),
          builder: (context, snapshot) {
            final profile = snapshot.hasData ? snapshot.data![0] as UserProfile? : null;
            final pendingAlerts = snapshot.hasData
                ? snapshot.data![1] as int
                : _pendingAlertsCount;
            final cards = _buildCards(profile, pendingAlerts);

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
                if (snapshot.hasError)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.warning),
                      title: const Text('No se pudo actualizar el inicio'),
                      subtitle: Text('${snapshot.error}'),
                    ),
                  ),
                _buildAlertSummaryCard(pendingAlerts),
                if (profile?.isAdmin == true)
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
        onPressed: () async {
          await Navigator.pushNamed(context, ReportFormScreen.routeName);
          if (!mounted) return;
          await _refreshHome();
        },
        icon: const Icon(Icons.add),
        label: const Text('Reportar'),
      ),
    );
  }
}
