import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/animal_report.dart';
import '../services/supabase_service.dart';
import '../widgets/report_card.dart';
import 'auth_screen.dart';
import 'report_detail_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({
    super.key,
    required this.isBackendConfigured,
  });

  static const routeName = '/my-reports';

  final bool isBackendConfigured;

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  late Future<List<AnimalReport>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _loadReports();
  }

  Future<List<AnimalReport>> _loadReports() async {
    if (!widget.isBackendConfigured) return [];

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    return SupabaseService().fetchReportsByUser(user.id);
  }

  Future<void> _refresh() async {
    setState(() => _reportsFuture = _loadReports());
    await _reportsFuture;
  }

  Future<void> _goToAuth() async {
    await Navigator.pushNamed(context, AuthScreen.routeName);
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _openReportDetail(AnimalReport report) async {
    await Navigator.pushNamed(
      context,
      ReportDetailScreen.routeName,
      arguments: report,
    );
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _closeReport(AnimalReport report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar reporte'),
          content: const Text(
            'El reporte quedará marcado como cerrado sin resolver. Podés usar el seguimiento para cambiarlo a otro estado si corresponde.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );

    if (confirm != true || report.id == null) return;

    try {
      await SupabaseService().closeOwnReport(reportId: report.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte cerrado.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cerrar el reporte: $error')),
      );
    }
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
              'Iniciá sesión para ver tus reportes.',
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

  Widget _buildReportActions(AnimalReport report) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _openReportDetail(report),
            icon: const Icon(Icons.timeline),
            label: const Text('Seguimiento'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: report.status == 'closed_unresolved'
                ? null
                : () => _closeReport(report),
            icon: const Icon(Icons.close),
            label: const Text('Cerrar'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.isBackendConfigured
        ? Supabase.instance.client.auth.currentUser
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis reportes'),
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
              '📌 Reportes publicados por mí',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Desde acá podés revisar tus casos, abrir el seguimiento o cerrarlos cuando corresponda.',
            ),
            const SizedBox(height: 22),
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
            else
              FutureBuilder<List<AnimalReport>>(
                future: _reportsFuture,
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
                        title: const Text('No se pudieron cargar tus reportes'),
                        subtitle: Text('${snapshot.error}'),
                      ),
                    );
                  }

                  final reports = snapshot.data ?? [];
                  if (reports.isEmpty) {
                    return const Card(
                      child: ListTile(
                        leading: Icon(Icons.pets),
                        title: Text('Todavía no publicaste reportes'),
                        subtitle: Text('Cuando publiques un caso aparecerá acá.'),
                      ),
                    );
                  }

                  return Column(
                    children: reports.map((report) {
                      return Column(
                        children: [
                          ReportCard(
                            report: report,
                            onTap: () => _openReportDetail(report),
                          ),
                          _buildReportActions(report),
                          const SizedBox(height: 16),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
