import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/adoption_request.dart';
import '../services/supabase_service.dart';

class AdoptionRequestsScreen extends StatefulWidget {
  const AdoptionRequestsScreen({
    super.key,
    required this.isBackendConfigured,
  });

  static const routeName = '/adoption-requests';

  final bool isBackendConfigured;

  @override
  State<AdoptionRequestsScreen> createState() => _AdoptionRequestsScreenState();
}

class _AdoptionRequestsScreenState extends State<AdoptionRequestsScreen> {
  late Future<List<AdoptionRequest>> _requestsFuture;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _requestsFuture = _loadRequests();
  }

  Future<List<AdoptionRequest>> _loadRequests() async {
    if (!widget.isBackendConfigured) return [];

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    return SupabaseService().fetchAdoptionRequestsForMyReports(user.id);
  }

  Future<void> _refresh() async {
    setState(() => _requestsFuture = _loadRequests());
    await _requestsFuture;
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'contacted':
        return 'Contactado';
      case 'approved':
        return 'Aprobado';
      case 'rejected':
        return 'Rechazado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  Future<void> _updateStatus(AdoptionRequest request, String status) async {
    setState(() => _isProcessing = true);

    try {
      await SupabaseService().updateAdoptionRequestStatus(
        requestId: request.id,
        status: status,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solicitud marcada como ${_statusLabel(status)}.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar la solicitud: $error')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildRequestCard(AdoptionRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.reportTitle ?? 'Reporte sin título',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Chip(label: Text(_statusLabel(request.status))),
            const SizedBox(height: 8),
            Text('Solicitante: ${request.requesterName?.isNotEmpty == true ? request.requesterName : request.requesterEmail ?? request.requesterId}'),
            if (request.requesterEmail != null) Text('Email: ${request.requesterEmail}'),
            const SizedBox(height: 8),
            Text('Mensaje: ${request.message?.isNotEmpty == true ? request.message : 'Sin mensaje'}'),
            const SizedBox(height: 8),
            Text(
              'Creada: ${request.createdAt.toLocal()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _updateStatus(request, 'contacted'),
                  icon: const Icon(Icons.mark_email_read),
                  label: const Text('Contactado'),
                ),
                FilledButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _updateStatus(request, 'approved'),
                  icon: const Icon(Icons.check),
                  label: const Text('Aprobar'),
                ),
                OutlinedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _updateStatus(request, 'rejected'),
                  icon: const Icon(Icons.close),
                  label: const Text('Rechazar'),
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
        title: const Text('Solicitudes de adopción'),
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
              '❤️ Solicitudes recibidas',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Acá aparecen las personas interesadas en adoptar animales publicados por vos.',
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
                  subtitle: Text('Iniciá sesión para ver solicitudes.'),
                ),
              )
            else
              FutureBuilder<List<AdoptionRequest>>(
                future: _requestsFuture,
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
                        title: const Text('No se pudieron cargar solicitudes'),
                        subtitle: Text('${snapshot.error}'),
                      ),
                    );
                  }

                  final requests = snapshot.data ?? [];
                  if (requests.isEmpty) {
                    return const Card(
                      child: ListTile(
                        leading: Icon(Icons.favorite_border),
                        title: Text('Sin solicitudes todavía'),
                        subtitle: Text('Cuando alguien solicite adoptar un animal publicado por vos aparecerá acá.'),
                      ),
                    );
                  }

                  return Column(
                    children: requests.map(_buildRequestCard).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
