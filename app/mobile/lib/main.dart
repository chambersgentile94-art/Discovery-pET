import 'package:flutter/material.dart';

void main() {
  runApp(const DiscoveryPetApp());
}

class DiscoveryPetApp extends StatelessWidget {
  const DiscoveryPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Discovery-pET',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B2CBF),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature estará disponible en la próxima etapa.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _HomeActionCard(
        icon: Icons.location_on,
        title: 'Ver mapa',
        description: 'Consultar mascotas perdidas, vistas o resguardadas cerca.',
        onTap: () => _showComingSoon(context, 'El mapa'),
      ),
      _HomeActionCard(
        icon: Icons.add_location_alt,
        title: 'Reportar animal',
        description: 'Publicar una mascota perdida, abandonada o vista en la calle.',
        onTap: () => _showComingSoon(context, 'El formulario de reportes'),
      ),
      _HomeActionCard(
        icon: Icons.favorite,
        title: 'Adopciones',
        description: 'Ver animales disponibles para adoptar.',
        onTap: () => _showComingSoon(context, 'La sección de adopciones'),
      ),
      _HomeActionCard(
        icon: Icons.person,
        title: 'Mi perfil',
        description: 'Gestionar usuario, contacto y participación como voluntario.',
        onTap: () => _showComingSoon(context, 'El perfil'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discovery-pET'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🐾 Ayudá a encontrar, rescatar o adoptar mascotas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Marcá en el mapa animales perdidos, abandonados o vistos en la calle. '
                    'La comunidad puede colaborar y dar seguimiento a cada caso.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Acciones principales',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...cards,
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showComingSoon(context, 'El formulario de reportes'),
        icon: const Icon(Icons.add),
        label: const Text('Reportar'),
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(description),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
