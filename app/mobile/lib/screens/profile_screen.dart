import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();

  User? _currentUser;
  UserProfile? _profile;
  String _role = 'user';
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    if (!widget.isBackendConfigured) return;

    setState(() => _isLoading = true);

    try {
      _currentUser = AuthService().currentUser;
      if (_currentUser != null) {
        _profile = await SupabaseService().fetchCurrentProfile();
        _fullNameController.text = _profile?.fullName ??
            (_currentUser?.userMetadata?['full_name'] as String? ?? '');
        _phoneController.text = _profile?.phone ?? '';
        _cityController.text = _profile?.city ?? '';
        _role = _profile?.role == 'admin' ? 'user' : (_profile?.role ?? 'user');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar el perfil: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _goToAuth() async {
    await Navigator.pushNamed(context, AuthScreen.routeName);
    if (!mounted) return;
    await _loadCurrentUser();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await SupabaseService().updateCurrentProfile(
        fullName: _fullNameController.text,
        phone: _phoneController.text,
        city: _cityController.text,
        role: _role,
      );

      await _loadCurrentUser();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el perfil: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    if (!widget.isBackendConfigured) return;

    setState(() => _isLoading = true);

    try {
      await AuthService().signOut();
      if (!mounted) return;
      setState(() {
        _currentUser = null;
        _profile = null;
        _fullNameController.clear();
        _phoneController.clear();
        _cityController.clear();
        _role = 'user';
      });
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

  String _roleLabel(String role) {
    switch (role) {
      case 'volunteer':
        return 'Voluntario';
      case 'shelter':
        return 'Protectora / refugio';
      case 'vet':
        return 'Veterinaria';
      case 'user':
      default:
        return 'Usuario';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _currentUser != null;
    final email = _currentUser?.email ?? 'Usuario invitado';
    final title = _profile?.fullName?.isNotEmpty == true
        ? _profile!.fullName!
        : _fullNameController.text.trim().isNotEmpty
            ? _fullNameController.text.trim()
            : email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          if (isLoggedIn)
            IconButton(
              onPressed: _isLoading ? null : _loadCurrentUser,
              icon: const Icon(Icons.refresh),
            ),
        ],
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
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              isLoggedIn
                  ? 'Cuenta vinculada al backend · ${_roleLabel(_profile?.role ?? _role)}'
                  : widget.isBackendConfigured
                      ? 'Todavía no iniciaste sesión.'
                      : 'Backend no configurado.',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoading) const LinearProgressIndicator(),
          if (!isLoggedIn)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _goToAuth,
                icon: const Icon(Icons.login),
                label: const Text('Acceder'),
              ),
            )
          else ...[
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresá tu nombre.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: email,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono / WhatsApp',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Ciudad',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _role,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de participación',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('Usuario')),
                      DropdownMenuItem(value: 'volunteer', child: Text('Voluntario')),
                      DropdownMenuItem(value: 'shelter', child: Text('Protectora / refugio')),
                      DropdownMenuItem(value: 'vet', child: Text('Veterinaria')),
                    ],
                    onChanged: (value) => setState(() => _role = value ?? 'user'),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveProfile,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Guardar perfil'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Card(
            child: ListTile(
              leading: Icon(Icons.volunteer_activism),
              title: Text('Participación'),
              subtitle: Text('Estos datos ayudan a coordinar rescates, adopciones y contacto comunitario.'),
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
