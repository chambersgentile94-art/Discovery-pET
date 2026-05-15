import 'package:flutter/material.dart';

import '../models/animal_report.dart';
import '../services/supabase_service.dart';
import '../widgets/report_card.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.isBackendConfigured,
  });

  static const routeName = '/map';

  final bool isBackendConfigured;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late Future<List<AnimalReport>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _loadReports();
  }

  Future<List<AnimalReport>> _loadReports() async {
    if (!widget.isBackendConfigured) return [];
    return SupabaseService().fetchPublicReports();
  }

  Future<void> _refresh() async {
    setState(() => _reportsFuture = _loadReports());
    await _reportsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de reportes'),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🗺️ Reportes cercanos',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Primera versión de lectura real desde Supabase. Luego se reemplazará por Google Maps con marcadores.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Perros')),
                Chip(label: Text('Gatos')),
                Chip(label: Text('Perdidos')),
                Chip(label: Text('Vistos')),
                Chip(label: Text('Urgentes')),
              ],
            ),
            const SizedBox(height: 20),
            if (!widget.isBackendConfigured)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.warning),
                  title: Text('Backend no configurado'),
                  subtitle: Text('Ejecutá la app con los parámetros del proyecto para leer reportes.'),
                ),
              )
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
                        title: const Text('No se pudieron cargar los reportes'),
                        subtitle: Text('${snapshot.error}'),
                      ),
                    );
                  }

                  final reports = snapshot.data ?? [];
                  if (reports.isEmpty) {
                    return const Card(
                      child: ListTile(
                        leading: Icon(Icons.pets),
                        title: Text('Sin reportes todavía'),
                        subtitle: Text('Cuando alguien publique un reporte aparecerá en esta lista.'),
                      ),
                    );
                  }

                  return Column(
                    children: reports
                        .map((report) => ReportCard(report: report))
                        .toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
