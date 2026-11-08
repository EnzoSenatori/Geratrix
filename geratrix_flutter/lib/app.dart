import 'package:flutter/material.dart';

import 'routes.dart';
import 'screens/index_screen.dart';
import 'screens/pin_screen.dart';
import 'theme/app_colors.dart';

// Raiz do app: tema do guia visual e rotas
class GeratrixApp extends StatelessWidget {
  const GeratrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geratrix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.onPrimaryContainer,
          secondary: AppColors.primaryStrong,
          onSecondary: AppColors.surface,
          error: AppColors.error,
          onError: AppColors.surface,
          errorContainer: AppColors.errorContainer,
          onErrorContainer: AppColors.error,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
          surfaceContainerHighest: AppColors.surfaceVariant,
          outline: AppColors.outline,
          outlineVariant: AppColors.outline,
        ),
        scaffoldBackgroundColor: AppColors.background,
        cardTheme: const CardThemeData(
          color: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 1,
          shadowColor: Color(0x330A2E2B),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
      ),
      initialRoute: AppRoutes.index,
      routes: {
        AppRoutes.index: (context) => const IndexScreen(),
        AppRoutes.pin: (context) => const PinScreen(),
      },
    );
  }
}