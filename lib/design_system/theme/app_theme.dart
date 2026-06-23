import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          surface: AppColors.surface,
          error: AppColors.danger,
        ),
        scaffoldBackgroundColor: AppColors.background,
        // Flat design — no shadows
        cardTheme: const CardThemeData(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppSpacing.borderRadius)),
            side: BorderSide(color: AppColors.border),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.primaryContent,
            minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            textStyle: AppTypography.buttonText,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppSpacing.borderRadius)),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            textStyle: AppTypography.buttonText,
            side: const BorderSide(color: AppColors.primary),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppSpacing.borderRadius)),
            ),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppSpacing.borderRadius)),
            borderSide: BorderSide(color: AppColors.border),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: AppTypography.displayLg,
          displayMedium: AppTypography.displayMd,
          headlineLarge: AppTypography.headingLg,
          headlineMedium: AppTypography.headingMd,
          headlineSmall: AppTypography.headingSm,
          bodyLarge: AppTypography.bodyLg,
          bodyMedium: AppTypography.bodyMd,
          bodySmall: AppTypography.bodySm,
          labelLarge: AppTypography.label,
          labelSmall: AppTypography.caption,
        ),
        // No decorative shadows
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          titleTextStyle: AppTypography.headingLg,
        ),
      );
}
