import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/alert_preference.dart';
import '../models/animal_report.dart';
import '../services/supabase_service.dart';
import '../widgets/report_card.dart';
import 'auth_screen.dart';
import 'location_picker_screen.dart';
import 'report_detail_screen.dart';

class AlertPreferencesScreen extends StatefulWidget {
  const AlertPreferencesScreen({
    super.key,
    required this.isBackendConfigured,
  });

  static const routeName = '/alert-preferences';

  final bool isBackendConfigured;

  @override
  State<AlertPreferencesScreen> createState() => _AlertPreferencesScreenState();
}

class _AlertPreferencesScreenState extends State<AlertPreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cityController = TextEditingController();
  final _latitudeController = TextEditingController(text: '-40.8135');
  final _longitudeController = TextEditingController(text: '-62.9967');
  final _radiusController = TextEditingController(text: '5');

  AlertPreference? _currentPreference;
  List<_ReportDistance> _matchingReports = [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLocating = false;
  bool _isLoadingMatches = false;
  bool _isEnabled = true;
  bool _notifyLost = true;
  bool _notifySeen = true;
  bool _notifyAbandoned = true;
  bool _notifyInjured = true;
  bool _notifyAdoption = false;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  @override
  void dispose() {
    _cityController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _loadPreference() async {
    if (!widget.isBackendConfigured) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final preference = await SupabaseService().fetchCurrentAlertPreference();
      if (!mounted) return;

      if (preference != null) {
        _currentPreference = preference;
        _cityController.text = preference.city ?? '';
        _latitudeController.text =
            preference.latitude?.toStringAsFixed(7) ?? _latitudeController.text;
        _longitudeController.text =
            preference.longitude?.toStringAsFixed(7) ?? _longitudeController.text;
        _radiusController.text = preference.radiusKm.toStringAsFixed(0);
        _isEnabled = preference.isEnabled;
        _notifyLost = preference.notifyLost;
        _notifySeen = preference.notifySeen;
        _notifyAbandoned = preference.notifyAbandoned;
        _notifyInjured = preference.notifyInjured;
        _notifyAdoption = preference.notifyAdoption;
      }

      await _refreshMatches(showErrors: false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar las alertas: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Position> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('El servicio de ubicación está desactivado.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('No se otorgó permiso de ubicación.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      final position = await _getCurrentPosition();
      _latitudeController.text = position.latitude.toStringAsFixed(7);
      _longitudeController.text = position.longitude.toStringAsFixed(7);
      await _refreshMatches(showErrors: false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicación de alerta actualizada.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo obtener ubicación: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _openLocationPicker() async {
    final latitude = double.tryParse(_latitudeController.text.trim()) ?? -40.8135;
    final longitude = double.tryParse(_longitudeController.text.trim()) ?? -62.9967;

    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLatitude: latitude,
          initialLongitude: longitude,
        ),
      ),
    );

    if (result == null) return;

    _latitudeController.text = result.latitude.toStringAsFixed(7);
    _longitudeController.text = result.longitude.toStringAsFixed(7);
    await _refreshMatches(showErrors: false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Zona de alerta seleccionada.')),
    );
  }

  Future<void> _goToAuth() async {
    await Navigator.pushNamed(context, AuthScreen.routeName);
    if (!mounted) return;
    await _loadPreference();
  }

  Future<void> _savePreference() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tenés que iniciar sesión para configurar alertas.')),
      );
      return;
    }

    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    final radius = double.tryParse(_radiusController.text.trim());

    if (latitude == null || longitude == null || radius == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordenadas o radio inválidos.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final preference = AlertPreference(
        id: _currentPreference?.id,
        userId: user.id,
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        radiusKm: radius,
        notifyLost: _notifyLost,
        notifySeen: _notifySeen,
        notifyAbandoned: _notifyAbandoned,
        notifyInjured: _notifyInjured,
        notifyAdoption: _notifyAdoption,
        isEnabled: _isEnabled,
      );

      await SupabaseService().upsertAlertPreference(preference);
      await _loadPreference();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferencias de alerta guardadas.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron guardar las alertas: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _refreshMatches({bool showErrors = true}) async {
    if (!widget.isBackendConfigured) return;

    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    final radius = double.tryParse(_radiusController.text.trim());

    if (latitude == null || longitude == null || radius == null || radius <= 0) {
      return;
    }

    setState(() => _isLoadingMatches = true);

    try {
      final reports = await SupabaseService().fetchPublicReports();
      final matches = reports
          .where(_matchesSelectedCategories)
          .map((report) {
            final distance = _distanceKm(
              latitude,
              longitude,
              report.latitude,
              report.longitude,
            );
            return _ReportDistance(report: report, distanceKm: distance);
          })
          .where((item) => item.distanceKm <= radius)
          .toList()
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      if (!mounted) return;
      setState(() => _matchingReports = matches);
    } catch (error) {
      if (!mounted || !showErrors) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron calcular coincidencias: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingMatches = false);
    }
  }

  bool _matchesSelectedCategories(AnimalReport report) {
    switch (report.category) {
      case 'lost':
        return _notifyLost;
      case 'seen':
        return _notifySeen;
      case 'abandoned':
        return _notifyAbandoned;
      case 'injured':
        return _notifyInjured;
      case 'adoption':
        return _notifyAdoption;
      default:
        return false;
    }
  }

  double _distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) => degrees * pi / 180;

  Future<void> _openReportDetail(AnimalReport report) async {
    await Navigator.pushNamed(
      context,
      ReportDetailScreen.routeName,
      arguments: report,
    );
    if (!mounted) return;
    await _refreshMatches(showErrors: false);
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
              'Iniciá sesión para configurar alertas por zona.',
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

  Widget _buildCategorySwitches() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Categorías a notificar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SwitchListTile(
              value: _notifyLost,
              title: const Text('Mascotas perdidas'),
              onChanged: (value) {
                setState(() => _notifyLost = value);
                _refreshMatches(showErrors: false);
              },
            ),
            SwitchListTile(
              value: _notifySeen,
              title: const Text('Animales vistos'),
              onChanged: (value) {
                setState(() => _notifySeen = value);
                _refreshMatches(showErrors: false);
              },
            ),
            SwitchListTile(
              value: _notifyAbandoned,
              title: const Text('Animales abandonados'),
              onChanged: (value) {
                setState(() => _notifyAbandoned = value);
                _refreshMatches(showErrors: false);
              },
            ),
            SwitchListTile(
              value: _notifyInjured,
              title: const Text('Animales heridos'),
              onChanged: (value) {
                setState(() => _notifyInjured = value);
                _refreshMatches(showErrors: false);
              },
            ),
            SwitchListTile(
              value: _notifyAdoption,
              title: const Text('Adopciones'),
              onChanged: (value) {
                setState(() => _notifyAdoption = value);
                _refreshMatches(showErrors: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Reportes dentro de tu zona',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: _isLoadingMatches ? null : _refreshMatches,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoadingMatches)
              const LinearProgressIndicator()
            else if (!_isEnabled)
              const ListTile(
                leading: Icon(Icons.notifications_off),
                title: Text('Alertas pausadas'),
                subtitle: Text('Activá las alertas para usar esta zona.'),
              )
            else if (_matchingReports.isEmpty)
              const ListTile(
                leading: Icon(Icons.check_circle_outline),
                title: Text('Sin coincidencias actuales'),
                subtitle: Text('No hay reportes activos dentro del radio configurado.'),
              )
            else ...[
              Text(
                '${_matchingReports.length} reporte(s) coinciden con tu configuración actual.',
              ),
              const SizedBox(height: 12),
              ..._matchingReports.take(5).map(
                    (item) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A ${item.distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ReportCard(
                          report: item.report,
                          onTap: () => _openReportDetail(item.report),
                        ),
                      ],
                    ),
                  ),
              if (_matchingReports.length > 5)
                Text(
                  'Mostrando 5 de ${_matchingReports.length} coincidencias.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
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
        title: const Text('Alertas por zona'),
        actions: [
          if (user != null)
            IconButton(
              onPressed: _loadPreference,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '🔔 Alertas por zona',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Configurá una zona de interés para futuras notificaciones cuando se publiquen animales cerca.',
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
            if (_isLoading) const LinearProgressIndicator(),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  SwitchListTile(
                    value: _isEnabled,
                    title: const Text('Alertas activas'),
                    subtitle: const Text('Podés pausar las alertas sin borrar la configuración.'),
                    onChanged: (value) {
                      setState(() => _isEnabled = value);
                      _refreshMatches(showErrors: false);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Ciudad / zona',
                      hintText: 'Ej: Viedma, Patagones, barrio...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latitudeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Latitud',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (double.tryParse(value?.trim() ?? '') == null) {
                              return 'Inválida';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _longitudeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Longitud',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (double.tryParse(value?.trim() ?? '') == null) {
                              return 'Inválida';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _radiusController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Radio de alerta en km',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _refreshMatches(showErrors: false),
                    validator: (value) {
                      final radius = double.tryParse(value?.trim() ?? '');
                      if (radius == null || radius <= 0 || radius > 100) {
                        return 'Ingresá un radio entre 1 y 100 km.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openLocationPicker,
                          icon: const Icon(Icons.map),
                          label: const Text('Elegir en mapa'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLocating ? null : _useCurrentLocation,
                          icon: _isLocating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.my_location),
                          label: const Text('Mi ubicación'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCategorySwitches(),
                  const SizedBox(height: 12),
                  _buildMatchesPreview(),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _savePreference,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Guardar alertas'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportDistance {
  const _ReportDistance({
    required this.report,
    required this.distanceKm,
  });

  final AnimalReport report;
  final double distanceKm;
}
