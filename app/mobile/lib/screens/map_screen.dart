import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/animal_report.dart';
import '../services/supabase_service.dart';
import '../widgets/report_card.dart';
import 'report_detail_screen.dart';

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

  LatLng _initialCenter(List<AnimalReport> reports) {
    if (reports.isNotEmpty) {
      return LatLng(reports.first.latitude, reports.first.longitude);
    }

    return const LatLng(-40.8135, -62.9967);
  }

  Color _markerColor(AnimalReport report) {
    if (report.urgency == 'high') return Colors.red;
    if (report.category == 'adoption') return Colors.pink;
    if (report.category == 'lost') return Colors.orange;
    return Colors.deepPurple;
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

  void _showReportPreview(AnimalReport report) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReportCard(report: report),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _openReportDetail(report);
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Abrir seguimiento'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMap(List<AnimalReport> reports) {
    final center = _initialCenter(reports);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 380,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13,
            minZoom: 3,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.discoverypet.mobile',
            ),
            MarkerLayer(
              markers: reports.map((report) {
                return Marker(
                  point: LatLng(report.latitude, report.longitude),
                  width: 46,
                  height: 46,
                  child: GestureDetector(
                    onTap: () => _showReportPreview(report),
                    child: Icon(
                      Icons.location_on,
                      color: _markerColor(report),
                      size: 42,
                    ),
                  ),
                );
              }).toList(),
            ),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: const [
        Chip(
          avatar: Icon(Icons.location_on, color: Colors.red),
          label: Text('Urgente'),
        ),
        Chip(
          avatar: Icon(Icons.location_on, color: Colors.orange),
          label: Text('Perdido'),
        ),
        Chip(
          avatar: Icon(Icons.location_on, color: Colors.pink),
          label: Text('Adopción'),
        ),
        Chip(
          avatar: Icon(Icons.location_on, color: Colors.deepPurple),
          label: Text('Otros'),
        ),
      ],
    );
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
                    '🗺️ Mapa de reportes',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Tocá un marcador para ver el detalle del caso. Los reportes se cargan desde Supabase.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(context),
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
                        subtitle: Text('Cuando alguien publique un reporte aparecerá en el mapa.'),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMap(reports),
                      const SizedBox(height: 20),
                      Text(
                        'Reportes cargados: ${reports.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...reports.map(
                        (report) => ReportCard(
                          report: report,
                          onTap: () => _openReportDetail(report),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
