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
  PaymentMethod _method = PaymentMethod.cash;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _result;

  Future<void> _confirm() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(ordersRepositoryProvider);
      final result = await repo.closeOrder(
        orderId: widget.orderId,
        version: widget.version,
        payments: [
          {'amount': widget.total, 'paymentMethod': _method.apiValue},
        ],
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

    final total = double.tryParse(widget.total) ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Cobrar')),
      body: Center(
        child: SizedBox(
          width: 480,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Total a cobrar',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Método de pago',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...PaymentMethod.values.map(
                    (m) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _PaymentTile(
                        method: m,
                        selected: _method == m,
                        onTap: () => setState(() => _method = m),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.danger),
                      textAlign: TextAlign.center,
                    ),
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
                              color: AppColors.primaryContent,
                            ),
                          )
                        : const Text(
                            'Confirmar pago',
                            style: TextStyle(fontSize: 18),
                          ),
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
          color: selected ? AppColors.primary.withAlpha(20) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              method.icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              method.label,
              style: AppTypography.bodyLg.copyWith(
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
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

class _SuccessView extends ConsumerWidget {
  const _SuccessView({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = result['total']?.toString() ?? '—';
    final points = result['pointsEarned'] as int? ?? 0;

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 80,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '¡Pago confirmado!',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Total cobrado: \$$total',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (points > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '+$points puntos de lealtad',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.success),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: () => context.go('/tables'),
                    child: const Text('Volver a mesas'),
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
