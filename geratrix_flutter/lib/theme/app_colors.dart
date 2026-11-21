import 'package:flutter/material.dart';

// Cores do guia visual do Geratrix; só o app.dart usa este arquivo
class AppColors {
  AppColors._(); // não pode ser instanciada, como o AppRoutes

  static const primary = Color(0xFF2EC4B6); // verde-água: só preenchimento
  static const onPrimary = Color(0xFF0A2E2B); // texto sobre o verde-água
  static const primaryStrong = Color(0xFF0B7A70); // texto verde sobre branco
  static const primaryContainer = Color(0xFFD6F5F1);
  static const onPrimaryContainer = Color(0xFF0B5F57);
  static const background = Color(0xFFF3F6F6); // fundo das telas
  static const surface = Color(0xFFFFFFFF); // cards
  static const surfaceVariant = Color(0xFFE8EEEE); // campos e chips
  static const outline = Color(0xFFDDE5E5);
  static const textPrimary = Color(0xFF1B2627);
  static const textSecondary = Color(0xFF566A6D);
  static const error = Color(0xFFB3261E);
  static const errorContainer = Color(0xFFFDE8E7);
}