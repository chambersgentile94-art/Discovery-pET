import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.isBackendConfigured,
  });

  static const routeName = '/profile';

  final bool isBackendConfigured;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    if (!widget.isBackendConfigured) return;
    _currentUser = AuthService().currentUser;
  }

  Future<void> _goToAuth() async {
    await Navigator.pushNamed(context, AuthScreen.routeName);
    if (!mounted) return;
    setState(_loadCurrentUser);
  }

  Future<void> _signOut() async {
    if (!widget.isBackendConfigured) return;

    setState(() => _isLoading = true);

    try {
      await AuthService().signOut();
      if (!mounted) return;
      setState(() => _currentUser = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión cerrada.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cerrar sesión: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _currentUser != null;
    final email = _currentUser?.email ?? 'Usuario invitado';
    final fullName = _currentUser?.userMetadata?['full_name'] as String?;

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
            child: Icon(isLoggedIn ? Icons.verified_user : Icons.person, size: 42),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              fullName?.isNotEmpty == true ? fullName! : email,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              isLoggedIn
                  ? 'Cuenta vinculada al backend.'
                  : widget.isBackendConfigured
                      ? 'Todavía no iniciaste sesión.'
                      : 'Backend no configurado.',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          if (!isLoggedIn)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _goToAuth,
                icon: const Icon(Icons.login),
                label: const Text('Acceder'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
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
