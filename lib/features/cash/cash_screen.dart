import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/tokens/app_typography.dart';
import 'cash_repository.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _cashProvider =
    AsyncNotifierProvider<_CashNotifier, List<CashSessionModel>>(
        _CashNotifier.new);

class _CashNotifier extends AsyncNotifier<List<CashSessionModel>> {
  @override
  Future<List<CashSessionModel>> build() =>
      ref.read(cashRepositoryProvider).list();

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(cashRepositoryProvider).list());
  }

  Future<void> openSession(String amount) async {
    await ref.read(cashRepositoryProvider).open(amount);
    await reload();
  }

  Future<void> closeSession(String id, String declared) async {
    await ref
        .read(cashRepositoryProvider)
        .close(sessionId: id, closingAmountDeclared: declared);
    await reload();
  }

  Future<void> registerMovement({
    required String sessionId,
    required String type,
    required String amount,
    required String paymentMethod,
    String? notes,
  }) async {
    await ref.read(cashRepositoryProvider).registerMovement(
          sessionId: sessionId,
          type: type,
          amount: amount,
          paymentMethod: paymentMethod,
          notes: notes,
        );
    await reload();
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class CashScreen extends ConsumerWidget {
  const CashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_cashProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caja'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(_cashProvider.notifier).reload(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sessions) {
          final openSession =
              sessions.where((s) => s.isOpen).firstOrNull;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (openSession != null) ...[
                _ActiveSessionCard(session: openSession),
                const SizedBox(height: AppSpacing.lg),
              ] else ...[
                _OpenSessionCard(),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text('Historial de turnos',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.md),
              ...sessions.map((s) => _SessionHistoryTile(session: s)),
              if (sessions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Text('Sin turnos registrados'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Open session card ─────────────────────────────────────────────────────────

class _OpenSessionCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_OpenSessionCard> createState() =>
      _OpenSessionCardState();
}

class _OpenSessionCardState extends ConsumerState<_OpenSessionCard> {
  final _controller = TextEditingController(text: '500.00');
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary.withAlpha(15),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.point_of_sale_outlined,
                    color: AppColors.primary, size: 28),
                const SizedBox(width: AppSpacing.md),
                Text('Abrir turno de caja',
                    style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Ingresa el fondo inicial con el que arranca la caja.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                SizedBox(
                  width: 160,
                  child: TextFormField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Fondo inicial',
                      prefixText: '\$ ',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                FilledButton.icon(
                  onPressed: _loading
                      ? null
                      : () async {
                          final messenger =
                              ScaffoldMessenger.of(context);
                          setState(() => _loading = true);
                          try {
                            await ref
                                .read(_cashProvider.notifier)
                                .openSession(_controller.text.trim());
                          } catch (e) {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _loading = false);
                            }
                          }
                        },
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryContent),
                        )
                      : const Icon(Icons.play_arrow),
                  label: const Text('Abrir caja'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Active session card ───────────────────────────────────────────────────────

class _ActiveSessionCard extends ConsumerWidget {
  const _ActiveSessionCard({required this.session});
  final CashSessionModel session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elapsed = DateTime.now().difference(session.openedAt);
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);

    return Card(
      color: AppColors.success.withAlpha(15),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.point_of_sale,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Caja abierta',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: AppColors.success)),
                      Text(
                        'Fondo: \$${session.openingAmount} · ${hours}h ${minutes}m',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _ActionChip(
                  icon: Icons.add_circle_outline,
                  label: 'Entrada de efectivo',
                  color: AppColors.success,
                  onTap: () => _showMovementDialog(
                      context, ref, 'payin', 'Entrada de efectivo'),
                ),
                _ActionChip(
                  icon: Icons.remove_circle_outline,
                  label: 'Salida de efectivo',
                  color: AppColors.warning,
                  onTap: () => _showMovementDialog(
                      context, ref, 'payout', 'Salida de efectivo'),
                ),
                _ActionChip(
                  icon: Icons.receipt_long_outlined,
                  label: 'Corte de caja',
                  color: AppColors.info,
                  onTap: () => _showReport(context, ref),
                ),
                _ActionChip(
                  icon: Icons.stop_circle_outlined,
                  label: 'Cerrar turno',
                  color: AppColors.danger,
                  onTap: () => _showCloseDialog(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMovementDialog(
      BuildContext context, WidgetRef ref, String type, String title) {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String method = 'cash';
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      prefixText: '\$ ',
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Monto válido > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: method,
                    decoration:
                        const InputDecoration(labelText: 'Método'),
                    items: const [
                      DropdownMenuItem(
                          value: 'cash', child: Text('Efectivo')),
                      DropdownMenuItem(
                          value: 'card', child: Text('Tarjeta')),
                      DropdownMenuItem(
                          value: 'transfer',
                          child: Text('Transferencia')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => method = v);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notas (opcional)',
                      hintText: 'Cambio, propinas, gasto...',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                ref.read(_cashProvider.notifier).registerMovement(
                      sessionId: session.id,
                      type: type,
                      amount: amountCtrl.text.trim(),
                      paymentMethod: method,
                      notes: notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCloseDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar turno'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Cuenta el efectivo en caja y registra el monto declarado. '
                  'El sistema comparará con el monto esperado.',
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monto declarado en caja',
                    prefixText: '\$ ',
                  ),
                  autofocus: true,
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n < 0) return 'Monto válido';
                    return null;
                  },
                ),
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
                backgroundColor: AppColors.danger),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              ref.read(_cashProvider.notifier).closeSession(
                    session.id,
                    ctrl.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Cerrar turno'),
          ),
        ],
      ),
    );
  }

  void _showReport(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => _CashReportDialog(sessionId: session.id),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(label, style: TextStyle(color: color)),
      side: BorderSide(color: color.withAlpha(80)),
      onPressed: onTap,
    );
  }
}

// ── Cash report dialog ────────────────────────────────────────────────────────

class _CashReportDialog extends ConsumerWidget {
  const _CashReportDialog({required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<CashReportModel>(
      future: ref.read(cashRepositoryProvider).report(sessionId),
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
        final r = snap.data!;
        final session = r.session;
        final movements = r.movements;
        final revenue = r.revenue;
        final byMethod = r.byPaymentMethod;

        return AlertDialog(
          title: const Text('Corte de caja'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ReportRow('Fondo inicial',
                      '\$${session['openingAmount']}'),
                  const Divider(),
                  Text('Movimientos',
                      style: AppTypography.label
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.xs),
                  _ReportRow(
                    'Ventas (${movements['sales']?['count'] ?? 0})',
                    '\$${movements['sales']?['total'] ?? '0.00'}',
                  ),
                  _ReportRow(
                    'Entradas (${movements['payins']?['count'] ?? 0})',
                    '\$${movements['payins']?['total'] ?? '0.00'}',
                  ),
                  _ReportRow(
                    'Salidas (${movements['payouts']?['count'] ?? 0})',
                    '-\$${movements['payouts']?['total'] ?? '0.00'}',
                    valueColor: AppColors.danger,
                  ),
                  const Divider(),
                  Text('Por método de pago',
                      style: AppTypography.label
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.xs),
                  ...byMethod.entries.map((e) => _ReportRow(
                        _methodLabel(e.key),
                        '\$${e.value}',
                      )),
                  const Divider(),
                  Text('Ingresos',
                      style: AppTypography.label
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.xs),
                  _ReportRow(
                      'Venta bruta', '\$${revenue['gross'] ?? '0.00'}'),
                  _ReportRow(
                      'IVA recaudado',
                      '\$${revenue['ivaCollected'] ?? '0.00'}'),
                  _ReportRow(
                      'Venta neta', '\$${revenue['net'] ?? '0.00'}',
                      bold: true),
                  if (session['closingAmountSystem'] != null) ...[
                    const Divider(),
                    _ReportRow('Esperado en caja',
                        '\$${session['closingAmountSystem']}'),
                    if (session['closingAmountDeclared'] != null)
                      _ReportRow('Declarado',
                          '\$${session['closingAmountDeclared']}'),
                    if (session['difference'] != null)
                      _ReportRow(
                        'Diferencia',
                        '\$${session['difference']}',
                        valueColor: double.tryParse(
                                    session['difference'].toString()) ==
                                0
                            ? AppColors.success
                            : AppColors.danger,
                        bold: true,
                      ),
                  ],
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

  String _methodLabel(String key) => switch (key) {
        'cash' => 'Efectivo',
        'card' => 'Tarjeta',
        'transfer' => 'Transferencia',
        _ => key,
      };
}

class _ReportRow extends StatelessWidget {
  const _ReportRow(this.label, this.value,
      {this.valueColor, this.bold = false});

  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: bold
                  ? AppTypography.label
                  : Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: (bold ? AppTypography.label : AppTypography.bodyMd)
                .copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}

// ── Session history tile ──────────────────────────────────────────────────────

class _SessionHistoryTile extends ConsumerWidget {
  const _SessionHistoryTile({required this.session});
  final CashSessionModel session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date =
        '${session.openedAt.day}/${session.openedAt.month}/${session.openedAt.year}';
    final time =
        '${session.openedAt.hour.toString().padLeft(2, '0')}:${session.openedAt.minute.toString().padLeft(2, '0')}';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              session.isOpen ? AppColors.success : AppColors.textDisabled,
          child: Icon(
            session.isOpen ? Icons.lock_open : Icons.lock_outline,
            color: Colors.white,
            size: 18,
          ),
        ),
        title: Text(
          '$date — $time${session.cashierName != null ? ' · ${session.cashierName}' : ''}',
        ),
        subtitle: Text(
          session.isOpen
              ? 'Abierta — Fondo: \$${session.openingAmount}'
              : 'Declarado: \$${session.closingAmountDeclared ?? "—"} '
                  '| Sistema: \$${session.closingAmountSystem ?? "—"}',
        ),
        trailing: session.isOpen
            ? null
            : IconButton(
                icon: const Icon(Icons.receipt_long_outlined),
                tooltip: 'Ver corte',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) =>
                      _CashReportDialog(sessionId: session.id),
                ),
              ),
      ),
    );
  }
}
