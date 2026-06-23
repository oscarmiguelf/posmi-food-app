import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';

final _mxn = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

// ── Models ────────────────────────────────────────────────────────────────────

class _POItem {
  const _POItem({
    required this.ingredientId,
    required this.ingredientName,
    required this.quantity,
    required this.unitCost,
  });
  final String ingredientId;
  final String ingredientName;
  final double quantity;
  final double unitCost;

  factory _POItem.fromJson(Map<String, dynamic> json) => _POItem(
        ingredientId: json['ingredientId'] as String? ?? '',
        ingredientName:
            (json['ingredient'] as Map<String, dynamic>?)?['name']
                    as String? ??
                json['ingredientName'] as String? ??
                '',
        quantity:
            double.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
        unitCost:
            double.tryParse(json['unitCost']?.toString() ?? '0') ?? 0,
      );
}

class _POModel {
  const _POModel({
    required this.id,
    required this.status,
    required this.supplierName,
    required this.createdAt,
    required this.items,
    this.total,
  });
  final String id;
  final String status;
  final String supplierName;
  final DateTime createdAt;
  final List<_POItem> items;
  final double? total;

  factory _POModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return _POModel(
      id: json['id'] as String,
      status: json['status'] as String,
      supplierName:
          (json['supplier'] as Map<String, dynamic>?)?['name']
                  as String? ??
              '—',
      createdAt: DateTime.parse(json['createdAt'] as String),
      total:
          double.tryParse(json['totalAmount']?.toString() ?? '0'),
      items: rawItems
          .map((e) => _POItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Color get statusColor => switch (status) {
        'draft' => AppColors.warning,
        'sent' => AppColors.info,
        'received' => AppColors.success,
        'cancelled' => AppColors.danger,
        _ => AppColors.textSecondary,
      };

  String get statusLabel => switch (status) {
        'draft' => 'Borrador',
        'sent' => 'Enviada',
        'received' => 'Recibida',
        'cancelled' => 'Cancelada',
        _ => status,
      };
}

// ── Repository ────────────────────────────────────────────────────────────────

class _PORepo {
  _PORepo(this._dio);
  final Dio _dio;

  Future<List<_POModel>> list() async {
    final res =
        await _dio.get<Map<String, dynamic>>('/purchase-orders');
    final data = res.data!['data'] as List<dynamic>;
    return data
        .map((e) => _POModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> suggestions() async {
    final res = await _dio
        .get<Map<String, dynamic>>('/purchase-orders/suggestions');
    return (res.data!['data'] as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<void> create(Map<String, dynamic> body) async {
    await _dio.post<void>('/purchase-orders', data: body);
  }

  Future<void> send(String id) async {
    await _dio.patch<void>('/purchase-orders/$id/send');
  }

  Future<void> receive(
      String id, List<Map<String, dynamic>> receivedItems) async {
    await _dio.post<void>('/purchase-orders/$id/receive', data: {
      'items': receivedItems,
    });
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final _repoProvider =
    Provider<_PORepo>((ref) => _PORepo(ref.watch(dioProvider)));

final _poProvider =
    AsyncNotifierProvider<_PONotifier, List<_POModel>>(_PONotifier.new);

class _PONotifier extends AsyncNotifier<List<_POModel>> {
  @override
  Future<List<_POModel>> build() => ref.read(_repoProvider).list();

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state =
        await AsyncValue.guard(() => ref.read(_repoProvider).list());
  }

  Future<void> create(Map<String, dynamic> body) async {
    await ref.read(_repoProvider).create(body);
    await reload();
  }

  Future<void> send(String id) async {
    await ref.read(_repoProvider).send(id);
    await reload();
  }

  Future<void> receive(
      String id, List<Map<String, dynamic>> items) async {
    await ref.read(_repoProvider).receive(id, items);
    await reload();
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class PurchaseOrdersScreen extends ConsumerWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_poProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Órdenes de compra'),
        actions: [
          IconButton(
            tooltip: 'Sugerencias de compra',
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: () => _showSuggestions(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(_poProvider.notifier).reload(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: AppColors.textDisabled),
                  SizedBox(height: AppSpacing.md),
                  Text('Sin órdenes de compra'),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 80),
            itemCount: orders.length,
            separatorBuilder: (context, _) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => _POCard(po: orders[i]),
          );
        },
      ),
    );
  }

  void _showSuggestions(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => _SuggestionsDialog(repo: ref.read(_repoProvider)),
    );
  }
}

// ── PO Card ───────────────────────────────────────────────────────────────────

class _POCard extends ConsumerWidget {
  const _POCard({required this.po});
  final _POModel po;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = DateFormat('dd/MM/yyyy').format(po.createdAt);

    return Card(
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: 2),
          decoration: BoxDecoration(
            color: po.statusColor.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: po.statusColor.withAlpha(100)),
          ),
          child: Text(po.statusLabel,
              style: AppTypography.caption.copyWith(
                  color: po.statusColor, fontWeight: FontWeight.bold)),
        ),
        title: Text(po.supplierName),
        subtitle: Text(
          '$date · ${po.items.length} items'
          '${po.total != null ? ' · ${_mxn.format(po.total)}' : ''}',
        ),
        children: [
          // Items list
          ...po.items.map((item) => ListTile(
                dense: true,
                title: Text(item.ingredientName),
                trailing: Text(
                  '${item.quantity} × ${_mxn.format(item.unitCost)}',
                  style: AppTypography.caption,
                ),
              )),
          // Actions
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (po.status == 'draft')
                  FilledButton.icon(
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Enviar a proveedor'),
                    onPressed: () =>
                        ref.read(_poProvider.notifier).send(po.id),
                  ),
                if (po.status == 'sent') ...[
                  FilledButton.icon(
                    icon: const Icon(Icons.inventory, size: 16),
                    label: const Text('Recibir mercancía'),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success),
                    onPressed: () =>
                        _showReceiveDialog(context, ref, po),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReceiveDialog(
      BuildContext context, WidgetRef ref, _POModel po) {
    final controllers = <String, TextEditingController>{};
    for (final item in po.items) {
      controllers[item.ingredientId] =
          TextEditingController(text: item.quantity.toString());
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recibir mercancía'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Verifica las cantidades recibidas:'),
                const SizedBox(height: AppSpacing.md),
                ...po.items.map((item) => Padding(
                      padding: const EdgeInsets.only(
                          bottom: AppSpacing.sm),
                      child: TextFormField(
                        controller: controllers[item.ingredientId],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: item.ingredientName,
                          helperText:
                              'Ordenado: ${item.quantity}',
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.success),
            onPressed: () {
              final receivedItems = po.items.map((item) {
                final qty = double.tryParse(
                        controllers[item.ingredientId]?.text ?? '') ??
                    item.quantity;
                return {
                  'ingredientId': item.ingredientId,
                  'quantityReceived': qty,
                };
              }).toList();
              ref
                  .read(_poProvider.notifier)
                  .receive(po.id, receivedItems);
              Navigator.pop(ctx);
            },
            child: const Text('Confirmar recepción'),
          ),
        ],
      ),
    );
  }
}

// ── Suggestions dialog ────────────────────────────────────────────────────────

class _SuggestionsDialog extends StatelessWidget {
  const _SuggestionsDialog({required this.repo});
  final _PORepo repo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: repo.suggestions(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const AlertDialog(
            content: SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snap.hasError) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('${snap.error}'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar')),
            ],
          );
        }
        final suggestions = snap.data ?? [];
        if (suggestions.isEmpty) {
          return AlertDialog(
            title: const Text('Sugerencias de compra'),
            content:
                const Text('No hay sugerencias en este momento.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar')),
            ],
          );
        }
        return AlertDialog(
          title: const Text('Sugerencias de compra'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Basado en consumo de 30 días + 14 días de buffer:',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...suggestions.map((s) {
                    final name =
                        s['ingredientName']?.toString() ?? '—';
                    final suggested = double.tryParse(
                            s['suggestedQuantity']?.toString() ??
                                '0') ??
                        0;
                    final supplier =
                        s['lastSupplierName']?.toString();
                    final unit =
                        s['unit']?.toString() ?? '';
                    return Card(
                      child: ListTile(
                        title: Text(name),
                        subtitle: Text(
                          'Sugerido: ${suggested.toStringAsFixed(1)} $unit'
                          '${supplier != null ? ' · Proveedor: $supplier' : ''}',
                        ),
                        leading: const Icon(
                            Icons.shopping_cart_outlined,
                            color: AppColors.warning),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar')),
          ],
        );
      },
    );
  }
}
