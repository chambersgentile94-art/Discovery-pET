import 'package:flutter/material.dart';

import '../models/animal_report.dart';
import '../services/supabase_service.dart';
import '../widgets/report_card.dart';
import 'report_detail_screen.dart';

class AdoptionScreen extends StatefulWidget {
  const AdoptionScreen({
    super.key,
    required this.isBackendConfigured,
  });

  static const routeName = '/adoptions';

  final bool isBackendConfigured;

  @override
  State<AdoptionScreen> createState() => _AdoptionScreenState();
}

class _AdoptionScreenState extends State<AdoptionScreen> {
  late Future<List<AnimalReport>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _loadReports();
  }

  Future<List<AnimalReport>> _loadReports() async {
    if (!widget.isBackendConfigured) return [];
    final reports = await SupabaseService().fetchPublicReports();
    return reports.where((report) => report.category == 'adoption').toList();
  }

  Future<void> _refresh() async {
    setState(() => _reportsFuture = _loadReports());
    await _reportsFuture;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adopciones'),
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
              '❤️ Mascotas en adopción',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Animales resguardados que buscan familia. Esta lista se alimenta de reportes reales con categoría adopción.',
            ),
            const SizedBox(height: 24),
            if (!widget.isBackendConfigured)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.warning),
                  title: Text('Backend no configurado'),
                  subtitle: Text('Ejecutá la app con los parámetros del proyecto para leer adopciones.'),
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
                        title: const Text('No se pudieron cargar adopciones'),
                        subtitle: Text('${snapshot.error}'),
                      ),
                    );
                  }

                  final reports = snapshot.data ?? [];
                  if (reports.isEmpty) {
                    return const Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Icon(Icons.pets)),
                        title: Text('Sin publicaciones todavía'),
                        subtitle: Text('Cuando existan animales en adopción aparecerán acá.'),
                      ),
                    );
                  }

                  return Column(
                    children: reports
                        .map(
                          (report) => ReportCard(
                            report: report,
                            onTap: () => _openReportDetail(report),
                          ),
                        )
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
