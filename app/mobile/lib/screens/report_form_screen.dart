import 'package:flutter/material.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  static const routeName = '/report-form';

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String _animalType = 'dog';
  String _category = 'lost';
  String _urgency = 'medium';

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Formulario validado. Próximo paso: guardar en Supabase.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Próximo paso: adjuntar foto.')),
                );
              },
              icon: const Icon(Icons.photo_camera),
              label: const Text('Agregar foto'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Próximo paso: detectar ubicación.')),
                );
              },
              icon: const Icon(Icons.my_location),
              label: const Text('Usar mi ubicación'),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send),
              label: const Text('Publicar reporte'),
            ),
          ],
        ),
      ),
    );
  }
}
