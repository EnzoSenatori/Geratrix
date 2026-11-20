import 'package:flutter/material.dart';

import '../models/cuidador.dart';
import '../routes.dart';

// Tela de Abertura de Turno: exibe dados do turno anterior e alertas do seed.py
class AbrirTurnoScreen extends StatelessWidget {
  const AbrirTurnoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cuidador = ModalRoute.of(context)?.settings.arguments as Cuidador?;
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Abertura de Turno'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  Text(
                    'Turno anterior',
                    style: textos.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Encerrado às 07:00 por Rafael de Oliveira Corrêa (Noite)',
                    style: textos.bodyLarge?.copyWith(color: cores.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),

                  // Seção de Alertas do Turno Anterior
                  Text(
                    'ALERTAS E OCORRÊNCIAS',
                    style: textos.labelMedium?.copyWith(
                      color: cores.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: cores.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_rounded, color: cores.error, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Pressão arterial — Maria das Graças (165 mmHg)',
                                  style: textos.bodyMedium?.copyWith(
                                    color: cores.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.warning_rounded, color: cores.error, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Glicemia capilar — José Augusto (250 mg/dL)',
                                  style: textos.bodyMedium?.copyWith(
                                    color: cores.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: cores.error, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Banho assistido — Antônio Ferreira (Não realizado: dormindo)',
                                  style: textos.bodyMedium?.copyWith(
                                    color: cores.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Seção de Passagem de Plantão
                  Text(
                    'PASSAGEM DE PLANTÃO',
                    style: textos.labelMedium?.copyWith(
                      color: cores.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Dona Maria acordou duas vezes durante a noite. Sr. José recusou o lanche das 22h.',
                        style: textos.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Seção de Pendências
                  Text(
                    'PENDÊNCIAS DO TURNO ANTERIOR',
                    style: textos.labelMedium?.copyWith(
                      color: cores.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Troca de fraldas — Terezinha Lima (05:00)',
                        style: textos.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Botão de início de plantão
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.lista);
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text('Iniciar plantão (${cuidador?.nome ?? "Cuidador"})'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}