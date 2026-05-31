import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/alert_event.dart';
import '../services/supabase_service.dart';
import '../widgets/report_card.dart';
import 'auth_screen.dart';
import 'report_detail_screen.dart';

class AlertEventsScreen extends StatefulWidget {
  const AlertEventsScreen({
    super.key,
    required this.isBackendConfigured,
  });

  static const routeName = '/alert-events';

  final bool isBackendConfigured;

  @override
  State<AlertEventsScreen> createState() => _AlertEventsScreenState();
}

class _AlertEventsScreenState extends State<AlertEventsScreen> {
  late Future<List<AlertEvent>> _eventsFuture;
  RealtimeChannel? _alertsChannel;
  bool _isRecalculating = false;
  bool _isRealtimeConnected = false;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _loadEvents();
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

  Future<List<AlertEvent>> _loadEvents() async {
    if (!widget.isBackendConfigured) return [];
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];
    return SupabaseService().fetchCurrentUserAlertEvents();
  }

  void _subscribeToAlertEvents() {
    if (!widget.isBackendConfigured) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final oldChannel = _alertsChannel;
    if (oldChannel != null) {
      Supabase.instance.client.removeChannel(oldChannel);
    }

    _alertsChannel = Supabase.instance.client
        .channel('alert-events-${user.id}')
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
            _refresh();
          },
        )
        .subscribe((status, [_]) {
          if (!mounted) return;
          setState(() {
            _isRealtimeConnected = status == RealtimeSubscribeStatus.subscribed;
          });
        });
  }

  Future<void> _refresh() async {
    final nextEventsFuture = _loadEvents();
    setState(() {
      _eventsFuture = nextEventsFuture;
    });
    await nextEventsFuture;
  }

  Future<void> _recalculate() async {
    setState(() {
      _isRecalculating = true;
    });

    try {
      final created = await SupabaseService().recalculateCurrentUserAlertEvents();
      await _refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alertas recalculadas. Nuevas: $created')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron recalcular alertas: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRecalculating = false;
        });
      }
    }
  }

  Future<void> _goToAuth() async {
    await Navigator.pushNamed(context, AuthScreen.routeName);
    if (!mounted) return;
    _subscribeToAlertEvents();
    await _refresh();
  }

  Future<void> _openReport(AlertEvent event) async {
    final report = event.report;
    if (report == null) return;

    if (event.isPending) {
      await SupabaseService().updateAlertEventStatus(
        eventId: event.id,
        status: 'seen',
      );
    }

    if (!mounted) return;
    await Navigator.pushNamed(
      context,
      ReportDetailScreen.routeName,
      arguments: report,
    );
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _dismiss(AlertEvent event) async {
    await SupabaseService().updateAlertEventStatus(
      eventId: event.id,
      status: 'dismissed',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alerta descartada.')),
    );
    await _refresh();
  }

  Widget _buildLoggedOutState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(Icons.lock, size: 42),
            const SizedBox(height: 12),
            const Text(
              'Iniciá sesión para ver tus alertas.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _goToAuth,
              icon: const Icon(Icons.login),
              label: const Text('Acceder'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealtimeStatus() {
    return Card(
      child: ListTile(
        leading: Icon(
          _isRealtimeConnected ? Icons.bolt : Icons.sync_disabled,
          color: _isRealtimeConnected ? Theme.of(context).colorScheme.primary : null,
        ),
        title: Text(
          _isRealtimeConnected
              ? 'Actualización en tiempo real activa'
              : 'Tiempo real no conectado',
        ),
        subtitle: Text(
          _isRealtimeConnected
              ? 'Esta pantalla se actualiza sola cuando llega una alerta nueva.'
              : 'Podés usar refrescar o recalcular alertas manualmente.',
        ),
      ),
    );
  }

  Widget _buildEvent(AlertEvent event) {
    final report = event.report;
    final isDismissed = event.status == 'dismissed';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  event.isPending ? Icons.notifications_active : Icons.notifications,
                  color: event.isPending ? Theme.of(context).colorScheme.primary : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    event.isPending ? 'Nueva alerta' : 'Alerta ${event.status}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text('${event.distanceKm.toStringAsFixed(1)} km'),
              ],
            ),
            const SizedBox(height: 10),
            if (report == null)
              const ListTile(
                leading: Icon(Icons.warning),
                title: Text('Reporte no disponible'),
                subtitle: Text('El reporte pudo haber sido cerrado, ocultado o eliminado.'),
              )
            else
              ReportCard(
                report: report,
                onTap: isDismissed ? null : () => _openReport(event),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: report == null || isDismissed ? null : () => _openReport(event),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Ver caso'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isDismissed ? null : () => _dismiss(event),
                    icon: const Icon(Icons.close),
                    label: const Text('Descartar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.isBackendConfigured
        ? Supabase.instance.client.auth.currentUser
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis alertas'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              '🔔 Mis alertas',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Acá aparecerán reportes nuevos que coincidan con tu zona y categorías configuradas.',
            ),
            const SizedBox(height: 18),
            if (!widget.isBackendConfigured)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.warning),
                  title: Text('Backend no configurado'),
                  subtitle: Text('Ejecutá la app con los parámetros del proyecto.'),
                ),
              )
            else if (user == null)
              _buildLoggedOutState()
            else ...[
              _buildRealtimeStatus(),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('Recalcular alertas'),
                  subtitle: const Text('Genera alertas sobre reportes existentes que coincidan con tu zona.'),
                  trailing: _isRecalculating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _isRecalculating ? null : _recalculate,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<AlertEvent>>(
                future: _eventsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.error),
                        title: const Text('No se pudieron cargar tus alertas'),
                        subtitle: Text('${snapshot.error}'),
                      ),
                    );
                  }

                  final events = snapshot.data ?? [];
                  if (events.isEmpty) {
                    return const Card(
                      child: ListTile(
                        leading: Icon(Icons.notifications_none),
                        title: Text('Sin alertas generadas'),
                        subtitle: Text('Cuando se publiquen reportes compatibles con tu zona aparecerán acá.'),
                      ),
                    );
                  }

                  final pendingCount = events.where((event) => event.isPending).length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.notifications_active),
                          title: Text('$pendingCount alerta(s) pendiente(s)'),
                          subtitle: Text('Total histórico: ${events.length}'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...events.map(_buildEvent),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
