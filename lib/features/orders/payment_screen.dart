import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/tokens/app_typography.dart';
import 'orders_repository.dart';

enum PaymentMethod { cash, card, transfer }

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cash => 'Efectivo',
        PaymentMethod.card => 'Tarjeta',
        PaymentMethod.transfer => 'Transferencia',
      };

  String get apiValue => switch (this) {
        PaymentMethod.cash => 'cash',
        PaymentMethod.card => 'card',
        PaymentMethod.transfer => 'transfer',
      };

  IconData get icon => switch (this) {
        PaymentMethod.cash => Icons.payments_outlined,
        PaymentMethod.card => Icons.credit_card,
        PaymentMethod.transfer => Icons.account_balance_outlined,
      };
}

class _PaymentEntry {
  _PaymentEntry({required this.method, required this.amount});
  PaymentMethod method;
  double amount;
}

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({
    super.key,
    required this.orderId,
    required this.total,
    required this.version,
  });

  final String orderId;
  final String total;
  final int version;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isSplit = false;
  PaymentMethod _singleMethod = PaymentMethod.cash;
  final List<_PaymentEntry> _splits = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _result;

  double get _total => double.tryParse(widget.total) ?? 0;

  double get _splitAssigned =>
      _splits.fold(0.0, (sum, e) => sum + e.amount);

  double get _splitRemaining => _total - _splitAssigned;

  void _addSplit() {
    final remaining = _splitRemaining;
    if (remaining <= 0) return;
    setState(() {
      _splits.add(_PaymentEntry(
        method: PaymentMethod.cash,
        amount: remaining,
      ));
    });
  }

  void _removeSplit(int index) {
    setState(() => _splits.removeAt(index));
  }

  Future<void> _confirm() async {
    List<Map<String, dynamic>> payments;

    if (_isSplit) {
      if (_splits.isEmpty) {
        setState(() => _error = 'Agrega al menos un pago');
        return;
      }
      final assigned = _splitAssigned;
      if ((assigned - _total).abs() > 0.01) {
        setState(() => _error =
            'Los pagos suman \$${assigned.toStringAsFixed(2)} '
            'pero el total es \$${_total.toStringAsFixed(2)}');
        return;
      }
      payments = _splits
          .map((e) => {
                'amount': e.amount.toStringAsFixed(2),
                'paymentMethod': e.method.apiValue,
              })
          .toList();
    } else {
      payments = [
        {'amount': widget.total, 'paymentMethod': _singleMethod.apiValue},
      ];
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(ordersRepositoryProvider);
      final result = await repo.closeOrder(
        orderId: widget.orderId,
        version: widget.version,
        payments: payments,
      );
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) return _SuccessView(result: _result!);

    return Scaffold(
      appBar: AppBar(title: const Text('Cobrar')),
      body: Center(
        child: SizedBox(
          width: 520,
          child: Card(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Total
                  Text('Total a cobrar',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '\$${_total.toStringAsFixed(2)}',
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Toggle split
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Pago único'),
                        selected: !_isSplit,
                        onSelected: (_) =>
                            setState(() => _isSplit = false),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ChoiceChip(
                        label: const Text('Dividir cuenta'),
                        selected: _isSplit,
                        onSelected: (_) => setState(() {
                          _isSplit = true;
                          if (_splits.isEmpty) _addSplit();
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (!_isSplit) ...[
                    // Single payment
                    Text('Método de pago',
                        style:
                            Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.md),
                    ...PaymentMethod.values.map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppSpacing.sm),
                        child: _PaymentTile(
                          method: m,
                          selected: _singleMethod == m,
                          onTap: () =>
                              setState(() => _singleMethod = m),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Split payments
                    Text('Pagos parciales',
                        style:
                            Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.md),
                    ...List.generate(_splits.length, (i) {
                      final entry = _splits[i];
                      return Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppSpacing.md),
                        child: _SplitRow(
                          entry: entry,
                          remaining: _splitRemaining,
                          onChanged: (method, amount) {
                            setState(() {
                              _splits[i] = _PaymentEntry(
                                  method: method, amount: amount);
                            });
                          },
                          onRemove: _splits.length > 1
                              ? () => _removeSplit(i)
                              : null,
                        ),
                      );
                    }),
                    // Remaining indicator
                    if (_splitRemaining.abs() > 0.01)
                      Container(
                        padding:
                            const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: _splitRemaining > 0
                              ? AppColors.warning.withAlpha(20)
                              : AppColors.danger.withAlpha(20),
                          borderRadius: BorderRadius.circular(
                              AppSpacing.borderRadius),
                        ),
                        child: Text(
                          _splitRemaining > 0
                              ? 'Faltan \$${_splitRemaining.toStringAsFixed(2)} por asignar'
                              : 'Excedente: \$${(-_splitRemaining).toStringAsFixed(2)}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _splitRemaining > 0
                                ? AppColors.warning
                                : AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed:
                          _splitRemaining > 0.01 ? _addSplit : null,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar otro pago'),
                    ),
                  ],

                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(_error!,
                        style: const TextStyle(color: AppColors.danger),
                        textAlign: TextAlign.center),
                  ],

                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryContent))
                        : const Text('Confirmar pago',
                            style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Split row ─────────────────────────────────────────────────────────────────

class _SplitRow extends StatelessWidget {
  const _SplitRow({
    required this.entry,
    required this.remaining,
    required this.onChanged,
    this.onRemove,
  });

  final _PaymentEntry entry;
  final double remaining;
  final void Function(PaymentMethod method, double amount) onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Method selector
          DropdownButton<PaymentMethod>(
            value: entry.method,
            underline: const SizedBox.shrink(),
            items: PaymentMethod.values
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(m.icon, size: 18),
                          const SizedBox(width: 6),
                          Text(m.label),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v, entry.amount);
            },
          ),
          const SizedBox(width: AppSpacing.md),
          // Amount input
          Expanded(
            child: TextFormField(
              initialValue: entry.amount.toStringAsFixed(2),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                prefixText: '\$ ',
                labelText: 'Monto',
              ),
              onChanged: (v) {
                final amount = double.tryParse(v) ?? 0;
                onChanged(entry.method, amount);
              },
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: AppColors.danger, size: 20),
              onPressed: onRemove,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Single payment tile ───────────────────────────────────────────────────────

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primary.withAlpha(20) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(method.icon,
                color:
                    selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Text(
              method.label,
              style: AppTypography.bodyLg.copyWith(
                color:
                    selected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ── Success view with ticket ──────────────────────────────────────────────────

class _SuccessView extends ConsumerWidget {
  const _SuccessView({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total =
        double.tryParse(result['total']?.toString() ?? '0') ?? 0;
    final points = result['pointsEarned'] as int? ?? 0;
    final items = result['items'] as List<dynamic>? ?? [];
    final payments = result['payments'] as List<dynamic>? ?? [];
    final ticketData = result['ticketData'] as Map<String, dynamic>?;

    final subtotal =
        ticketData?['subtotal']?.toString() ?? _calcSubtotal(total);
    final iva = ticketData?['iva']?.toString() ?? _calcIva(total);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SizedBox(
          width: 420,
          child: Card(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppColors.success, size: 56),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Pago confirmado',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: AppColors.success)),
                  const Divider(height: AppSpacing.xl),

                  // Items
                  if (items.isNotEmpty) ...[
                    ...items.map((raw) {
                      final item = raw as Map<String, dynamic>;
                      final name =
                          (item['menuItem'] as Map<String, dynamic>?)
                                  ?['name'] ??
                              item['menuItemName'] ??
                              '';
                      final qty = item['quantity'] ?? 1;
                      final price = double.tryParse(
                              item['unitPriceWithTax']?.toString() ??
                                  '0') ??
                          0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            SizedBox(
                                width: 28,
                                child: Text('$qty',
                                    style: AppTypography.label)),
                            Expanded(child: Text('$name')),
                            Text(
                                '\$${(price * qty).toStringAsFixed(2)}'),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: AppSpacing.lg),
                  ],

                  // Subtotal + IVA
                  _TicketRow('Subtotal', '\$$subtotal'),
                  _TicketRow('IVA (16%)', '\$$iva'),
                  const Divider(height: AppSpacing.md),
                  _TicketRow('TOTAL',
                      '\$${total.toStringAsFixed(2)}',
                      bold: true, large: true),

                  // Payment methods
                  if (payments.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text('Pagos',
                        style: AppTypography.label
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.xs),
                    ...payments.map((raw) {
                      final p = raw as Map<String, dynamic>;
                      final method = switch (p['paymentMethod']) {
                        'cash' => 'Efectivo',
                        'card' => 'Tarjeta',
                        'transfer' => 'Transferencia',
                        _ => p['paymentMethod']?.toString() ?? '',
                      };
                      return _TicketRow(method,
                          '\$${p['amount']?.toString() ?? '—'}');
                    }),
                  ],

                  // Loyalty
                  if (points > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(15),
                        borderRadius: BorderRadius.circular(
                            AppSpacing.borderRadius),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star,
                              color: AppColors.success, size: 18),
                          const SizedBox(width: AppSpacing.xs),
                          Text('+$points puntos de lealtad',
                              style: AppTypography.label
                                  .copyWith(color: AppColors.success)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),
                  FilledButton.icon(
                    onPressed: () => context.go('/tables'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver a mesas'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _calcSubtotal(double total) =>
      (total / 1.16).toStringAsFixed(2);
  String _calcIva(double total) =>
      (total - total / 1.16).toStringAsFixed(2);
}

class _TicketRow extends StatelessWidget {
  const _TicketRow(this.label, this.value,
      {this.bold = false, this.large = false});

  final String label;
  final String value;
  final bool bold;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final style = large
        ? Theme.of(context).textTheme.headlineSmall
        : bold
            ? AppTypography.label
            : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: style?.copyWith(
                  fontWeight: bold ? FontWeight.bold : null)),
          Text(value,
              style: style?.copyWith(
                  fontWeight: bold ? FontWeight.bold : null,
                  color: large ? AppColors.primary : null)),
        ],
      ),
    );
  }
}
