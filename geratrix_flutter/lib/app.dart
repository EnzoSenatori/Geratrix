import 'package:flutter/material.dart';

import 'routes.dart';
import 'screens/abrir_turno_screen.dart';
import 'screens/checkin_medicamento_screen.dart';
import 'screens/checkin_sinais_vitais_screen.dart';
import 'screens/checkin_tarefa_screen.dart';
import 'screens/encerrar_turno_screen.dart';
import 'screens/exercicio_screen.dart';
import 'screens/gestor_screen.dart';
import 'screens/historico_turnos_screen.dart';
import 'screens/index_screen.dart';
import 'screens/lista_screen.dart';
import 'screens/nao_realizado_screen.dart';
import 'screens/pin_screen.dart';
import 'screens/residente_screen.dart';

class GeratrixApp extends StatelessWidget {
  const GeratrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    final coresScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF006A60),
      primary: const Color(0xFF006A60),
      secondary: const Color(0xFF005249),
    );

    return MaterialApp(
      title: 'Geratrix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: coresScheme,
        scaffoldBackgroundColor: const Color(0xFFF8FAF9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8FAF9),
          foregroundColor: Color(0xFF191C1B),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, 52),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: const InputDecorationThemeData(
          filled: true,
          fillColor: Color(0xFFE0E3E1),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Color(0xFF005249), width: 2),
          ),
        ),
      ),
      initialRoute: AppRoutes.index,
      routes: {
        AppRoutes.index: (context) => const IndexScreen(),
        AppRoutes.pin: (context) => const PinScreen(),
        AppRoutes.abrirTurno: (context) => const AbrirTurnoScreen(),
        AppRoutes.lista: (context) => const ListaScreen(),
        AppRoutes.checkin: (context) => const CheckinTarefaScreen(),
        AppRoutes.checkinMedicamento: (context) => const CheckinMedicamentoScreen(),
        AppRoutes.checkinSinaisVitais: (context) => const CheckinSinaisVitaisScreen(),
        AppRoutes.naoRealizado: (context) => const NaoRealizadoScreen(),
        AppRoutes.residente: (context) => const ResidenteScreen(),
        AppRoutes.gestor: (context) => const GestorScreen(),
        AppRoutes.historicoTurnos: (context) => const HistoricoTurnosScreen(),
        AppRoutes.encerrarTurno: (context) => const EncerrarTurnoScreen(),
        AppRoutes.exercicio: (context) => const ExercicioScreen(),
      },
    );
  }
}