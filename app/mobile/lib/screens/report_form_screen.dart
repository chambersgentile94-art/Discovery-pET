import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../models/animal_report.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';
import 'location_picker_screen.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({
    super.key,
    required this.config,
  });

  static const routeName = '/report-form';

  final AppConfig config;

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController(text: '-40.8135');
  final _longitudeController = TextEditingController(text: '-62.9967');
  final _contactPhoneController = TextEditingController();

  final _imagePicker = ImagePicker();

  XFile? _selectedImage;
  String _animalType = 'dog';
  String _category = 'lost';
  String _urgency = 'medium';
  bool _showContactPhone = false;
  bool _isSaving = false;
  bool _isLocating = false;
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadProfileContact();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileContact() async {
    setState(() => _isLoadingProfile = true);
    try {
      final UserProfile? profile = await SupabaseService().fetchCurrentProfile();
      if (!mounted) return;
      _contactPhoneController.text = profile?.phone ?? '';
      if (_addressController.text.trim().isEmpty && profile?.city != null) {
        _addressController.text = profile!.city!;
      }
    } catch (_) {
      // El teléfono es opcional; no bloquea la creación del reporte.
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 78,
      maxWidth: 1600,
    );

    if (image == null) return;

    setState(() => _selectedImage = image);
  }

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Elegir desde galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
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
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
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
        const SnackBar(content: Text('Ubicación cargada correctamente.')),
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
          isGoogleMapsConfigured: widget.config.hasMapsConfig,
        ),
      ),
    );

    if (result == null) return;

    _latitudeController.text = result.latitude.toStringAsFixed(7);
    _longitudeController.text = result.longitude.toStringAsFixed(7);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coordenadas seleccionadas.')),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tenés que iniciar sesión para publicar un reporte.'),
        ),
      );
      return;
    }

    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Latitud o longitud inválida.')),
      );
      return;
    }

    final contactPhone = _contactPhoneController.text.trim();
    if (_showContactPhone && contactPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá un teléfono o desactivá mostrar contacto.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final service = SupabaseService();
      final report = AnimalReport(
        animalType: _animalType,
        category: _category,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        status: 'reported',
        urgency: _urgency,
        latitude: latitude,
        longitude: longitude,
        approximateAddress: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        contactPhone: contactPhone.isEmpty ? null : contactPhone,
        showContactPhone: _showContactPhone,
      );

      final reportId = await service.createReport(
        createdBy: currentUser.id,
        report: report,
      );

      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        final extension = _selectedImage!.name.split('.').last;

        await service.uploadReportImage(
          reportId: reportId,
          bytes: bytes,
          fileExtension: extension,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte publicado correctamente.')),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo publicar el reporte: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageName = _selectedImage?.name;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar animal'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Datos del reporte',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _animalType,
              decoration: const InputDecoration(
                labelText: 'Tipo de animal',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'dog', child: Text('Perro')),
                DropdownMenuItem(value: 'cat', child: Text('Gato')),
                DropdownMenuItem(value: 'other', child: Text('Otro')),
              ],
              onChanged: (value) => setState(() => _animalType = value ?? 'dog'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'lost', child: Text('Mascota perdida')),
                DropdownMenuItem(value: 'seen', child: Text('Animal visto')),
                DropdownMenuItem(value: 'abandoned', child: Text('Animal abandonado')),
                DropdownMenuItem(value: 'rescued', child: Text('Animal resguardado')),
                DropdownMenuItem(value: 'adoption', child: Text('En adopción')),
                DropdownMenuItem(value: 'injured', child: Text('Animal herido')),
              ],
              onChanged: (value) => setState(() => _category = value ?? 'lost'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                hintText: 'Ej: Perro marrón visto cerca de la plaza',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresá un título.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Color, tamaño, estado, comportamiento, collar, etc.',
                border: OutlineInputBorder(),
              ),
              minLines: 4,
              maxLines: 6,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresá una descripción.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _urgency,
              decoration: const InputDecoration(
                labelText: 'Urgencia',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Baja')),
                DropdownMenuItem(value: 'medium', child: Text('Media')),
                DropdownMenuItem(value: 'high', child: Text('Alta')),
              ],
              onChanged: (value) => setState(() => _urgency = value ?? 'medium'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Ubicación aproximada',
                hintText: 'Ej: Plaza San Martín, Viedma',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
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
                        return 'Latitud inválida.';
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
                        return 'Longitud inválida.';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _openLocationPicker,
              icon: const Icon(Icons.map),
              label: const Text('Seleccionar coordenadas en el mapa'),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contacto opcional',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Podés mostrar un teléfono o WhatsApp para coordinar el caso. Si lo desactivás, no se verá públicamente.',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contactPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Teléfono / WhatsApp',
                        border: const OutlineInputBorder(),
                        suffixIcon: _isLoadingProfile
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _showContactPhone,
                      title: const Text('Mostrar teléfono en este reporte'),
                      subtitle: const Text('Activá solo si querés que otros usuarios puedan contactarte directo.'),
                      onChanged: (value) => setState(() => _showContactPhone = value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _showImageSourceSheet,
              icon: const Icon(Icons.photo_camera),
              label: Text(imageName == null ? 'Agregar foto' : 'Foto: $imageName'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isLocating ? null : _useCurrentLocation,
              icon: _isLocating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: const Text('Usar mi ubicación actual'),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _submit,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: const Text('Publicar reporte'),
            ),
          ],
        ),
      ),
    );
  }
}
