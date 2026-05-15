import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const routeName = '/profile';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: const Icon(Icons.person, size: 42),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Usuario invitado',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('Próximo paso: login con Supabase Auth.'),
          ),
          const SizedBox(height: 24),
          const Card(
            child: ListTile(
              leading: Icon(Icons.volunteer_activism),
              title: Text('Participación'),
              subtitle: Text('Usuario, voluntario, protectora o veterinaria.'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Alertas por zona'),
              subtitle: Text('Próxima etapa: notificaciones por ubicación.'),
            ),
          ),
        ],
      ),
    );
  }
}
