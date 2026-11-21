import 'package:flutter/material.dart';

import 'screens/exercicio_screen.dart';

// Entrada de teste: abre só a tela da caneleira, sem depender do app do Theo
// Na pasta geratrix_flutter:
// flutter run -d chrome -t lib/main_caneleira.dart --dart-define=MQTT_SENHA=<senha do geratrix_g01>
void main() {
  runApp(const CaneleiraTesteApp());
}

// App mínimo da caneleira, com um tema provisório próximo do guia visual
class CaneleiraTesteApp extends StatelessWidget {
  const CaneleiraTesteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geratrix · Caneleira',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2EC4B6), // verde-água do guia visual
        scaffoldBackgroundColor: const Color(0xFFF3F6F6),
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
      ),
      home: const ExercicioScreen(),
    );
  }
}