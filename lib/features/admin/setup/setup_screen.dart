import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';

/// Pantalla de onboarding/configuración inicial.
/// Guía al admin a través de los pasos necesarios para operar el sistema.
class SetupScreen extends ConsumerWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración inicial')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              icon: Icons.checklist_outlined,
              title: 'Pasos para empezar a operar',
              subtitle:
                  'Completa estos pasos en orden antes de abrir el sistema a tu equipo.',
            ),
            const SizedBox(height: AppSpacing.lg),
            _SetupStep(
              number: 1,
              title: 'Mesas',
              description:
                  'Define las mesas de tu restaurante con su nombre y capacidad.',
              icon: Icons.table_restaurant_outlined,
              actionLabel: 'Ir a Mesas',
              onTap: () => context.go('/admin/tables'),
            ),
            _SetupStep(
              number: 2,
              title: 'Estaciones de preparación',
              description:
                  'Crea las estaciones (Cocina, Barra, Postres…). '
                  'Los platillos se enrutan automáticamente al KDS de cada estación.',
              icon: Icons.kitchen_outlined,
              actionLabel: 'Ir a Estaciones',
              onTap: () => context.go('/admin/stations'),
            ),
            _SetupStep(
              number: 3,
              title: 'Ingredientes',
              description:
                  'Registra tu catálogo de insumos con costo, unidad y stock inicial.',
              icon: Icons.inventory_2_outlined,
              actionLabel: 'Ir a Ingredientes',
              onTap: () => context.go('/admin/ingredients'),
            ),
            _SetupStep(
              number: 4,
              title: 'Menú',
              description:
                  'Agrega los platillos con su precio final (IVA incluido). '
                  'El sistema calcula el desglose automáticamente.',
              icon: Icons.menu_book_outlined,
              actionLabel: 'Ir a Menú',
              onTap: () => context.go('/admin/menu'),
            ),
            _SetupStep(
              number: 5,
              title: 'Usuarios',
              description:
                  'Crea cuentas para tu equipo: meseros, cajeros y cocineros '
                  'con los permisos de su rol.',
              icon: Icons.people_outline,
              actionLabel: 'Ir a Usuarios',
              onTap: () => context.go('/admin/users'),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _CredentialInfo(),
            const SizedBox(height: AppSpacing.xl),
            const _QuickReferenceCard(),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          ),
          child: Icon(icon, color: AppColors.primary, size: 28),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.actionLabel,
    required this.onTap,
  });

  final int number;
  final String title;
  final String description;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step number badge
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: AppTypography.label.copyWith(
                    color: AppColors.primaryContent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Text(title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(description,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                                color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Action
              OutlinedButton(
                onPressed: onTap,
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CredentialInfo extends StatelessWidget {
  const _CredentialInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withAlpha(15),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(color: AppColors.info.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.info, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text('Credenciales del administrador inicial',
                  style: AppTypography.label
                      .copyWith(color: AppColors.info)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow('Correo', 'admin@demo.com'),
          _InfoRow('Contraseña', 'Admin1234!'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Cambia la contraseña después del primer inicio de sesión.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.info),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:',
                style: AppTypography.label
                    .copyWith(color: AppColors.textSecondary)),
          ),
          Text(value,
              style: AppTypography.label.copyWith(
                  fontFamily: 'monospace',
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _QuickReferenceCard extends StatelessWidget {
  const _QuickReferenceCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Roles disponibles',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            const _RoleRow(
              role: 'Admin',
              color: AppColors.primary,
              perms:
                  'Acceso total: reportes, configuración, descuentos, usuarios.',
            ),
            const _RoleRow(
              role: 'Mesero',
              color: AppColors.success,
              perms:
                  'Ver mesas, tomar órdenes, gestionar reservaciones y clientes.',
            ),
            const _RoleRow(
              role: 'Cajero',
              color: AppColors.warning,
              perms:
                  'Cobrar órdenes, abrir/cerrar caja, registrar movimientos.',
            ),
            const _RoleRow(
              role: 'Cocina',
              color: AppColors.danger,
              perms: 'Ver órdenes en KDS y marcar como listas.',
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.role,
    required this.color,
    required this.perms,
  });

  final String role;
  final Color color;
  final String perms;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 2),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withAlpha(100)),
            ),
            child: Text(role,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                    color: color, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(perms,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
