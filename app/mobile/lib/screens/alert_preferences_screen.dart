import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/alert_preference.dart';
import '../services/supabase_service.dart';
import 'auth_screen.dart';
import 'location_picker_screen.dart';

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
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLocating = false;
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
              onChanged: (value) => setState(() => _notifyLost = value),
            ),
            SwitchListTile(
              value: _notifySeen,
              title: const Text('Animales vistos'),
              onChanged: (value) => setState(() => _notifySeen = value),
            ),
            SwitchListTile(
              value: _notifyAbandoned,
              title: const Text('Animales abandonados'),
              onChanged: (value) => setState(() => _notifyAbandoned = value),
            ),
            SwitchListTile(
              value: _notifyInjured,
              title: const Text('Animales heridos'),
              onChanged: (value) => setState(() => _notifyInjured = value),
            ),
            SwitchListTile(
              value: _notifyAdoption,
              title: const Text('Adopciones'),
              onChanged: (value) => setState(() => _notifyAdoption = value),
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
                    onChanged: (value) => setState(() => _isEnabled = value),
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
