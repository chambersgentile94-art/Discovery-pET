import 'package:flutter/material.dart';

class AdoptionScreen extends StatelessWidget {
  const AdoptionScreen({super.key});

  static const routeName = '/adoptions';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adopciones'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            '❤️ Mascotas en adopción',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'Esta sección mostrará animales resguardados que buscan familia. '
            'En la próxima etapa se conectará con reportes de categoría adopción.',
          ),
          SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Icon(Icons.pets)),
              title: Text('Sin publicaciones todavía'),
              subtitle: Text('Cuando existan animales en adopción aparecerán acá.'),
            ),
          ),
        ],
      ),
    );
  }
}
