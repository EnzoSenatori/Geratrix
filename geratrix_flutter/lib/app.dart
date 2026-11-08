import 'package:flutter/material.dart';

import 'routes.dart';
import 'screens/abrir_turno_screen.dart';
import 'screens/checkin_medicamento_screen.dart';
import 'screens/checkin_sinais_vitais_screen.dart';
import 'screens/checkin_tarefa_screen.dart';
import 'screens/encerrar_turno_screen.dart';
import 'screens/erro_screen.dart';
import 'screens/gestor_screen.dart';
import 'screens/historico_turnos_screen.dart';
import 'screens/index_screen.dart';
import 'screens/lista_screen.dart';
import 'screens/nao_realizado_screen.dart';
import 'screens/pin_screen.dart';
import 'screens/residente_screen.dart';
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
        AppRoutes.gestor: (context) => const GestorScreen(),
        AppRoutes.abrirTurno: (context) => const AbrirTurnoScreen(),
        AppRoutes.lista: (context) => const ListaScreen(),
        AppRoutes.checkin: (context) => const CheckinTarefaScreen(),
        AppRoutes.checkinSinaisVitais: (context) => const CheckinSinaisVitaisScreen(),
        AppRoutes.checkinMedicamento: (context) => const CheckinMedicamentoScreen(),
        AppRoutes.naoRealizado: (context) => const NaoRealizadoScreen(),
        AppRoutes.residente: (context) => const ResidenteScreen(),
        AppRoutes.encerrarTurno: (context) => const EncerrarTurnoScreen(),
        AppRoutes.historicoTurnos: (context) => const HistoricoTurnosScreen(),
      },
      // Tratamento de rotas desconhecidas (404)
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const ErroScreen(),
        );
      },
    );
  }
}