import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PickedLocation {
  const PickedLocation({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.isGoogleMapsConfigured,
  });

  final double initialLatitude;
  final double initialLongitude;
  final bool isGoogleMapsConfigured;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  late LatLng _selectedPoint;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _selectedPoint = LatLng(widget.initialLatitude, widget.initialLongitude);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
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

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final newPoint = LatLng(position.latitude, position.longitude);
      setState(() => _selectedPoint = newPoint);

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newPoint, zoom: 16),
        ),
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

  void _confirmLocation() {
    Navigator.pop(
      context,
      PickedLocation(
        latitude: _selectedPoint.latitude,
        longitude: _selectedPoint.longitude,
      ),
    );
  }

  Widget _buildMissingConfig() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.map_outlined, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Google Maps no está configurado',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Para seleccionar coordenadas desde el mapa tenés que configurar la API key de Google Maps. Mientras tanto podés usar el botón de ubicación actual o cargar coordenadas manualmente.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _isLocating ? null : _useCurrentLocation,
                  icon: _isLocating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: const Text('Usar ubicación actual'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _confirmLocation,
                  child: const Text('Confirmar coordenadas actuales'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final marker = Marker(
      markerId: const MarkerId('selected-location'),
      position: _selectedPoint,
      infoWindow: const InfoWindow(title: 'Ubicación seleccionada'),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar ubicación'),
        actions: [
          IconButton(
            onPressed: _confirmLocation,
            icon: const Icon(Icons.check),
            tooltip: 'Confirmar ubicación',
          ),
        ],
      ),
      body: widget.isGoogleMapsConfigured
          ? Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedPoint,
                    zoom: 14,
                  ),
                  myLocationButtonEnabled: false,
                  myLocationEnabled: true,
                  markers: {marker},
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: (point) => setState(() => _selectedPoint = point),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Tocá el mapa para mover el marcador.\n${_selectedPoint.latitude.toStringAsFixed(7)}, ${_selectedPoint.longitude.toStringAsFixed(7)}',
                      ),
                    ),
                  ),
                ),
              ],
            )
          : _buildMissingConfig(),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'use-current-location',
            onPressed: _isLocating ? null : _useCurrentLocation,
            child: _isLocating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'confirm-location',
            onPressed: _confirmLocation,
            icon: const Icon(Icons.check),
            label: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
