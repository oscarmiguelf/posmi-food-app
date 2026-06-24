import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import 'users_repository.dart';

final _usersProvider =
    AsyncNotifierProvider<_UsersNotifier, List<UserModel>>(
        _UsersNotifier.new);

final _rolesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(usersRepositoryProvider).getRoles();
});

final _stationsListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/stations');
  return (res.data!['data'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList();
});

class _UsersNotifier extends AsyncNotifier<List<UserModel>> {
  @override
  Future<List<UserModel>> build() =>
      ref.read(usersRepositoryProvider).getAll();

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(usersRepositoryProvider).getAll());
  }

  Future<void> create(Map<String, dynamic> body) async {
    await ref.read(usersRepositoryProvider).create(body);
    await reload();
  }

  Future<void> toggleActive(UserModel user) async {
    await ref.read(usersRepositoryProvider).update(user.id, {
      'isActive': !user.isActive,
      'version': 0,
    });
    await reload();
  }
}

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_usersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(_usersProvider.notifier).reload(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Nuevo usuario'),
        onPressed: () => _showCreateDialog(context, ref),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (users) => Card(
          margin: const EdgeInsets.all(AppSpacing.md),
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: users.length,
            separatorBuilder: (context, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final user = users[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: user.isActive
                      ? AppColors.primary
                      : AppColors.textDisabled,
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(user.name),
                subtitle: Text(
                  '${user.email} · ${user.roleName}'
                  '${user.stationName != null ? ' · ${user.stationName}' : ''}',
                ),
                trailing: Switch(
                  value: user.isActive,
                  activeThumbColor: AppColors.success,
                  onChanged: (_) => ref
                      .read(_usersProvider.notifier)
                      .toggleActive(user),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => Consumer(
        builder: (ctx, dialogRef, _) {
          final rolesAsync = dialogRef.watch(_rolesProvider);
          final stationsAsync = dialogRef.watch(_stationsListProvider);
          if (rolesAsync.isLoading || stationsAsync.isLoading) {
            return const AlertDialog(
              content: SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          return _CreateUserDialog(
            roles: rolesAsync.value ?? [],
            stations: stationsAsync.value ?? [],
            onSave: (body) =>
                ref.read(_usersProvider.notifier).create(body),
          );
        },
      ),
    );
  }
}

class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog({
    required this.roles,
    required this.stations,
    required this.onSave,
  });

  final List<Map<String, dynamic>> roles;
  final List<Map<String, dynamic>> stations;
  final void Function(Map<String, dynamic>) onSave;

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _roleId;
  String? _stationId;

  bool get _isKitchenRole {
    if (_roleId == null) return false;
    final role = widget.roles.where((r) => r['id'] == _roleId).firstOrNull;
    return role?['name']?.toString().toLowerCase() == 'cocina';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo usuario'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(labelText: 'Correo electrónico'),
                validator: (v) =>
                    v == null || !v.contains('@') ? 'Correo inválido' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                validator: (v) =>
                    v == null || v.length < 8 ? 'Mínimo 8 caracteres' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _roleId,
                decoration: const InputDecoration(labelText: 'Rol'),
                hint: const Text('Selecciona un rol'),
                items: widget.roles
                    .map((r) => DropdownMenuItem<String>(
                          value: r['id'] as String,
                          child: Text(r['name'] as String? ?? ''),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _roleId = v),
                validator: (v) => v == null ? 'Selecciona un rol' : null,
              ),
              if (_isKitchenRole && widget.stations.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _stationId,
                  decoration: const InputDecoration(
                    labelText: 'Estación',
                  ),
                  hint: const Text('Sin estación asignada'),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Sin estación'),
                    ),
                    ...widget.stations.map(
                      (s) => DropdownMenuItem<String>(
                        value: s['id'] as String,
                        child: Text(s['name'] as String? ?? ''),
                      ),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _stationId = v?.isEmpty == true ? null : v),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            widget.onSave({
              'name': _name.text.trim(),
              'email': _email.text.trim(),
              'password': _password.text,
              'roleId': _roleId,
              if (_stationId != null) 'stationId': _stationId,
            });
            Navigator.pop(context);
          },
          child: const Text('Crear'),
        ),
      ],
    );
  }
}
