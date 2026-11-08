import 'package:flutter/material.dart';

import '../models/cuidador.dart';
import '../routes.dart';
import '../widgets/perfil_tile.dart';

// Cuidadores do seed.py do backend, guardados em memória
const _cuidadores = [
  Cuidador(
    nome: 'Theo Casella Mendonça',
    iniciais: 'TCM',
    turnoPadrao: 'Manhã',
    pin: '1234',
  ),
  Cuidador(
    nome: 'Enzo Senatori',
    iniciais: 'ES',
    turnoPadrao: 'Tarde',
    pin: '1234',
  ),
  Cuidador(
    nome: 'Rafael de Oliveira Corrêa',
    iniciais: 'RC',
    turnoPadrao: 'Noite',
    pin: '1234',
  ),
];

// Tela inicial: o cuidador escolhe o próprio perfil para abrir o turno
class IndexScreen extends StatelessWidget {
  const IndexScreen({super.key});

  void _avisarEmConstrucao(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tela em construção')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final estiloSecao = textos.labelMedium?.copyWith(
      color: cores.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          children: [
            Text(
              'Geratrix',
              style: textos.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'Gestão de cuidado em ILPI',
              style: textos.bodyMedium?.copyWith(color: cores.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            Text(
              'Quem está abrindo o turno?',
              style: textos.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecione seu perfil para entrar com o PIN.',
              style: textos.bodyLarge?.copyWith(color: cores.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            Text('CUIDADORES', style: estiloSecao),
            const SizedBox(height: 12),
            for (final cuidador in _cuidadores) ...[
              PerfilTile(
                iniciais: cuidador.iniciais,
                titulo: cuidador.nome,
                subtitulo: 'Cuidador · Turno ${cuidador.turnoPadrao}',
                onTap: () {
                  // NOVO: Navega para o PIN passando o cuidador como argumento
                  Navigator.pushNamed(context, AppRoutes.pin, arguments: cuidador);
                },
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 20),
            Text('GESTÃO', style: estiloSecao),
            const SizedBox(height: 12),
            PerfilTile(
              iniciais: 'GD',
              titulo: 'Gestor — Direção',
              subtitulo: 'Acesso gerencial',
              destaque: true,
              onTap: () => _avisarEmConstrucao(context),
            ),
          ],
        ),
      ),
    );
  }
}