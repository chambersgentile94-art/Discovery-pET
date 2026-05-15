import 'package:flutter/material.dart';

import '../widgets/home_action_card.dart';
import 'adoption_screen.dart';
import 'map_screen.dart';
import 'my_reports_screen.dart';
import 'profile_screen.dart';
import 'report_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    final cards = [
      HomeActionCard(
        icon: Icons.location_on,
        title: 'Ver mapa',
        description: 'Consultar mascotas perdidas, vistas o resguardadas cerca.',
        onTap: () => Navigator.pushNamed(context, MapScreen.routeName),
      ),
      HomeActionCard(
        icon: Icons.add_location_alt,
        title: 'Reportar animal',
        description: 'Publicar una mascota perdida, abandonada o vista en la calle.',
        onTap: () => Navigator.pushNamed(context, ReportFormScreen.routeName),
      ),
      HomeActionCard(
        icon: Icons.assignment_ind,
        title: 'Mis reportes',
        description: 'Revisar, cerrar o dar seguimiento a los casos que publicaste.',
        onTap: () => Navigator.pushNamed(context, MyReportsScreen.routeName),
      ),
      HomeActionCard(
        icon: Icons.favorite,
        title: 'Adopciones',
        description: 'Ver animales disponibles para adoptar.',
        onTap: () => Navigator.pushNamed(context, AdoptionScreen.routeName),
      ),
      HomeActionCard(
        icon: Icons.person,
        title: 'Mi perfil',
        description: 'Gestionar usuario, contacto y participación como voluntario.',
        onTap: () => Navigator.pushNamed(context, ProfileScreen.routeName),
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
        onPressed: () => Navigator.pushNamed(context, ReportFormScreen.routeName),
        icon: const Icon(Icons.add),
        label: const Text('Reportar'),
      ),
    );
  }
}
