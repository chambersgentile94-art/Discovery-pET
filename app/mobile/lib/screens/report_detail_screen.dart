import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/animal_report.dart';
import '../models/report_update.dart';
import '../services/supabase_service.dart';
import '../widgets/report_card.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({super.key});

  static const routeName = '/report-detail';

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final _commentController = TextEditingController();
  final _flagReasonController = TextEditingController();
  final _service = SupabaseService();

  AnimalReport? _report;
  late Future<List<ReportUpdate>> _updatesFuture;
  String? _selectedStatus;
  bool _isSaving = false;
  bool _isFlagging = false;

  static const _statuses = [
    'reported',
    'searching',
    'recently_seen',
    'someone_going',
    'sheltered',
    'vet_care',
    'foster_home',
    'adoption',
    'adopted',
    'reunited',
    'closed_unresolved',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_report != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is AnimalReport) {
      _report = args;
      _selectedStatus = args.status;
      _updatesFuture = _service.fetchReportUpdates(args.id!);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _flagReasonController.dispose();
    super.dispose();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'reported':
        return 'Reportado';
      case 'searching':
        return 'En búsqueda';
      case 'recently_seen':
        return 'Visto recientemente';
      case 'someone_going':
        return 'Alguien va al lugar';
      case 'sheltered':
        return 'Resguardado';
      case 'vet_care':
        return 'En veterinaria';
      case 'foster_home':
        return 'En tránsito';
      case 'adoption':
        return 'En adopción';
      case 'adopted':
        return 'Adoptado';
      case 'reunited':
        return 'Reencontrado';
      case 'closed_unresolved':
        return 'Cerrado sin resolver';
      default:
        return status;
    }
  }

  Future<void> _refreshUpdates() async {
    final report = _report;
    if (report == null || report.id == null) return;

    setState(() => _updatesFuture = _service.fetchReportUpdates(report.id!));
    await _updatesFuture;
  }

  Future<void> _saveUpdate() async {
    final report = _report;
    final user = Supabase.instance.client.auth.currentUser;
    final comment = _commentController.text.trim();
    final newStatus = _selectedStatus;

    if (report == null || report.id == null || newStatus == null) return;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tenés que iniciar sesión para actualizar el caso.')),
      );
      return;
    }

    if (comment.isEmpty && newStatus == report.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agregá un comentario o cambiá el estado.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (newStatus != report.status) {
        await _service.updateReportStatus(reportId: report.id!, status: newStatus);
      }

      await _service.createReportUpdate(
        reportId: report.id!,
        userId: user.id,
        comment: comment,
        oldStatus: report.status,
        newStatus: newStatus == report.status ? null : newStatus,
      );

      _commentController.clear();
      setState(() {
        _report = report.copyWith(status: newStatus);
        _updatesFuture = _service.fetchReportUpdates(report.id!);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Actualización guardada.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la actualización: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showFlagDialog() async {
    _flagReasonController.clear();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reportar publicación'),
          content: TextField(
            controller: _flagReasonController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Motivo',
              hintText: 'Ej: información falsa, duplicado, imagen incorrecta...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () {
                final value = _flagReasonController.text.trim();
                if (value.isEmpty) return;
                Navigator.pop(context, value);
              },
              icon: const Icon(Icons.flag),
              label: const Text('Enviar'),
            ),
          ],
        );
      },
    );

    if (reason == null || reason.trim().isEmpty) return;
    await _flagReport(reason.trim());
  }

  Future<void> _flagReport(String reason) async {
    final report = _report;
    final user = Supabase.instance.client.auth.currentUser;

    if (report == null || report.id == null) return;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tenés que iniciar sesión para reportar una publicación.')),
      );
      return;
    }

    setState(() => _isFlagging = true);

    try {
      await _service.flagReport(
        reportId: report.id!,
        userId: user.id,
        reason: reason,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación reportada para revisión.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo reportar la publicación: $error')),
      );
    } finally {
      if (mounted) setState(() => _isFlagging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    if (report == null || report.id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del reporte')),
        body: const Center(child: Text('Reporte no disponible.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del reporte'),
        actions: [
          IconButton(
            onPressed: _isFlagging ? null : _showFlagDialog,
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Reportar publicación',
          ),
          IconButton(
            onPressed: _refreshUpdates,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshUpdates,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ReportCard(report: report),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seguimiento del caso',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Estado actual',
                        border: OutlineInputBorder(),
                      ),
                      items: _statuses
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(_statusLabel(status)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _selectedStatus = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Comentario / actualización',
                        hintText: 'Ej: Se lo vio nuevamente en la zona...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _saveUpdate,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Guardar actualización'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isFlagging ? null : _showFlagDialog,
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Reportar publicación inválida'),
            ),
            const SizedBox(height: 18),
            const Text(
              'Historial',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<ReportUpdate>>(
              future: _updatesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.error),
                      title: const Text('No se pudo cargar el historial'),
                      subtitle: Text('${snapshot.error}'),
                    ),
                  );
                }

                final updates = snapshot.data ?? [];
                if (updates.isEmpty) {
                  return const Card(
                    child: ListTile(
                      leading: Icon(Icons.history),
                      title: Text('Sin actualizaciones todavía'),
                      subtitle: Text('El seguimiento del caso aparecerá acá.'),
                    ),
                  );
                }

                return Column(
                  children: updates.map((update) {
                    final statusText = update.newStatus == null
                        ? 'Comentario'
                        : 'Estado: ${_statusLabel(update.oldStatus ?? '')} → ${_statusLabel(update.newStatus!)}';
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.update),
                        title: Text(statusText),
                        subtitle: Text(
                          '${update.comment.isEmpty ? 'Sin comentario' : update.comment}\n${update.createdAt.toLocal()}',
                        ),
                      ),
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
