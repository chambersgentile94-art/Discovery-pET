import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/report_flag.dart';
import '../services/supabase_service.dart';

class ModerationScreen extends StatefulWidget {
  const ModerationScreen({
    super.key,
    required this.isBackendConfigured,
  });

  static const routeName = '/moderation';

  final bool isBackendConfigured;

  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen> {
  late Future<List<ReportFlag>> _flagsFuture;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _flagsFuture = _loadFlags();
  }

  Future<List<ReportFlag>> _loadFlags() async {
    if (!widget.isBackendConfigured) return [];
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];
    return SupabaseService().fetchPendingFlags();
  }

  Future<void> _refresh() async {
    setState(() => _flagsFuture = _loadFlags());
    await _flagsFuture;
  }

  Future<void> _dismissFlag(ReportFlag flag) async {
    setState(() => _isProcessing = true);
    try {
      await SupabaseService().updateFlagStatus(
        flagId: flag.id,
        status: 'dismissed',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Denuncia descartada.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar la denuncia: $error')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _acceptFlag(ReportFlag flag, {required bool hideReport}) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(hideReport ? 'Aceptar y ocultar reporte' : 'Aceptar denuncia'),
          content: Text(
            hideReport
                ? 'La denuncia quedará aceptada y el reporte será ocultado del mapa público.'
                : 'La denuncia quedará aceptada, pero el reporte seguirá visible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      await SupabaseService().updateFlagStatus(
        flagId: flag.id,
        status: 'accepted',
      );

      if (hideReport) {
        await SupabaseService().hideReport(reportId: flag.reportId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hideReport
              ? 'Denuncia aceptada y reporte ocultado.'
              : 'Denuncia aceptada.'),
        ),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo procesar la denuncia: $error')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildFlagCard(ReportFlag flag) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              flag.reportTitle ?? 'Reporte sin título',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Motivo: ${flag.reason}'),
            const SizedBox(height: 8),
            Text(
              'Categoría: ${flag.reportCategory ?? '-'} · Urgencia: ${flag.reportUrgency ?? '-'}',
            ),
            const SizedBox(height: 8),
            Text(
              'Creada: ${flag.createdAt.toLocal()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _isProcessing ? null : () => _dismissFlag(flag),
                  icon: const Icon(Icons.close),
                  label: const Text('Descartar'),
                ),
                OutlinedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _acceptFlag(flag, hideReport: false),
                  icon: const Icon(Icons.check),
                  label: const Text('Aceptar'),
                ),
                FilledButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _acceptFlag(flag, hideReport: true),
                  icon: const Icon(Icons.visibility_off),
                  label: const Text('Aceptar y ocultar'),
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
        title: const Text('Moderación'),
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
              '🛡️ Denuncias pendientes',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Revisá publicaciones reportadas por la comunidad. Esta pantalla requiere permisos adecuados en Supabase.',
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
              const Card(
                child: ListTile(
                  leading: Icon(Icons.lock),
                  title: Text('Sesión requerida'),
                  subtitle: Text('Iniciá sesión para acceder a moderación.'),
                ),
              )
            else
              FutureBuilder<List<ReportFlag>>(
                future: _flagsFuture,
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
                        title: const Text('No se pudieron cargar denuncias'),
                        subtitle: Text('${snapshot.error}'),
                      ),
                    );
                  }

                  final flags = snapshot.data ?? [];
                  if (flags.isEmpty) {
                    return const Card(
                      child: ListTile(
                        leading: Icon(Icons.verified),
                        title: Text('Sin denuncias pendientes'),
                        subtitle: Text('Cuando existan publicaciones reportadas aparecerán acá.'),
                      ),
                    );
                  }

                  return Column(
                    children: flags.map(_buildFlagCard).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
