import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class _BusinessData {
  _BusinessData({
    required this.companyId,
    required this.companyName,
    required this.taxId,
    required this.branchId,
    required this.branchName,
    required this.address,
    required this.timezone,
  });

  final String companyId;
  final String companyName;
  final String? taxId;
  final String? branchId;
  final String? branchName;
  final String? address;
  final String timezone;

  factory _BusinessData.fromJson(Map<String, dynamic> json) {
    final company = json['company'] as Map<String, dynamic>;
    final branch = json['branch'] as Map<String, dynamic>?;
    return _BusinessData(
      companyId: company['id'] as String,
      companyName: company['name'] as String,
      taxId: company['taxId'] as String?,
      branchId: branch?['id'] as String?,
      branchName: branch?['name'] as String?,
      address: branch?['address'] as String?,
      timezone:
          (branch?['timezone'] as String?) ?? 'America/Mexico_City',
    );
  }
}

// ── Repository ────────────────────────────────────────────────────────────────

class _BusinessRepository {
  _BusinessRepository(this._dio);
  final Dio _dio;

  Future<_BusinessData> get() async {
    final res = await _dio.get<Map<String, dynamic>>('/business');
    return _BusinessData.fromJson(
        res.data!['data'] as Map<String, dynamic>);
  }

  Future<void> updateCompany(
      {required String name, required String? taxId}) async {
    await _dio.patch<void>('/business/company', data: {
      'name': name,
      if (taxId != null && taxId.isNotEmpty) 'taxId': taxId,
    });
  }

  Future<void> updateBranch({
    required String name,
    required String? address,
    required String timezone,
  }) async {
    await _dio.patch<void>('/business/branch', data: {
      'name': name,
      if (address != null && address.isNotEmpty) 'address': address,
      'timezone': timezone,
    });
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final _businessRepoProvider = Provider<_BusinessRepository>(
    (ref) => _BusinessRepository(ref.watch(dioProvider)));

final _businessProvider =
    AsyncNotifierProvider<_BusinessNotifier, _BusinessData>(
        _BusinessNotifier.new);

class _BusinessNotifier extends AsyncNotifier<_BusinessData> {
  @override
  Future<_BusinessData> build() =>
      ref.read(_businessRepoProvider).get();

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(_businessRepoProvider).get());
  }

  Future<void> saveCompany(String name, String? taxId) async {
    await ref
        .read(_businessRepoProvider)
        .updateCompany(name: name, taxId: taxId);
    await reload();
  }

  Future<void> saveBranch(
      String name, String? address, String timezone) async {
    await ref
        .read(_businessRepoProvider)
        .updateBranch(name: name, address: address, timezone: timezone);
    await reload();
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class BusinessScreen extends ConsumerWidget {
  const BusinessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_businessProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos del negocio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(_businessProvider.notifier).reload(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _SectionCard(
              icon: Icons.business_outlined,
              title: 'Empresa',
              subtitle: 'Nombre legal y RFC que aparecerán en los tickets.',
              child: _CompanyForm(
                data: data,
                onSave: (name, taxId) => ref
                    .read(_businessProvider.notifier)
                    .saveCompany(name, taxId),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionCard(
              icon: Icons.store_outlined,
              title: 'Sucursal',
              subtitle: 'Datos de la ubicación física del restaurante.',
              child: _BranchForm(
                data: data,
                onSave: (name, address, tz) => ref
                    .read(_businessProvider.notifier)
                    .saveBranch(name, address, tz),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(title,
                    style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
            const Divider(height: AppSpacing.xl),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Company form ──────────────────────────────────────────────────────────────

class _CompanyForm extends StatefulWidget {
  const _CompanyForm({required this.data, required this.onSave});

  final _BusinessData data;
  final Future<void> Function(String name, String? taxId) onSave;

  @override
  State<_CompanyForm> createState() => _CompanyFormState();
}

class _CompanyFormState extends State<_CompanyForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _taxId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.data.companyName);
    _taxId = TextEditingController(text: widget.data.taxId ?? '');
  }

  @override
  void didUpdateWidget(_CompanyForm old) {
    super.didUpdateWidget(old);
    if (old.data.companyName != widget.data.companyName) {
      _name.text = widget.data.companyName;
    }
    if (old.data.taxId != widget.data.taxId) {
      _taxId.text = widget.data.taxId ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _taxId.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        _name.text.trim(),
        _taxId.text.trim().isEmpty ? null : _taxId.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Empresa actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Nombre de la empresa',
              hintText: 'Tacos El Güero S.A. de C.V.',
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _taxId,
            decoration: const InputDecoration(
              labelText: 'RFC (opcional)',
              hintText: 'XAXX010101000',
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryContent),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Guardar empresa'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Branch form ───────────────────────────────────────────────────────────────

const _timezones = [
  'America/Mexico_City',
  'America/Cancun',
  'America/Chihuahua',
  'America/Hermosillo',
  'America/Mazatlan',
  'America/Monterrey',
  'America/Tijuana',
];

class _BranchForm extends StatefulWidget {
  const _BranchForm({required this.data, required this.onSave});

  final _BusinessData data;
  final Future<void> Function(String name, String? address, String tz)
      onSave;

  @override
  State<_BranchForm> createState() => _BranchFormState();
}

class _BranchFormState extends State<_BranchForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  late String _timezone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.data.branchName ?? '');
    _address =
        TextEditingController(text: widget.data.address ?? '');
    _timezone = _timezones.contains(widget.data.timezone)
        ? widget.data.timezone
        : _timezones.first;
  }

  @override
  void didUpdateWidget(_BranchForm old) {
    super.didUpdateWidget(old);
    if (old.data.branchName != widget.data.branchName) {
      _name.text = widget.data.branchName ?? '';
    }
    if (old.data.address != widget.data.address) {
      _address.text = widget.data.address ?? '';
    }
    if (old.data.timezone != widget.data.timezone) {
      _timezone = _timezones.contains(widget.data.timezone)
          ? widget.data.timezone
          : _timezones.first;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        _name.text.trim(),
        _address.text.trim().isEmpty ? null : _address.text.trim(),
        _timezone,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sucursal actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Nombre de la sucursal',
              hintText: 'Sucursal Centro',
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _address,
            decoration: const InputDecoration(
              labelText: 'Dirección (opcional)',
              hintText: 'Av. Juárez 123, Col. Centro, CDMX',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _timezone,
            decoration: const InputDecoration(labelText: 'Zona horaria'),
            items: _timezones
                .map((tz) => DropdownMenuItem(value: tz, child: Text(tz)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _timezone = v);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryContent),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Guardar sucursal'),
            ),
          ),
        ],
      ),
    );
  }
}
