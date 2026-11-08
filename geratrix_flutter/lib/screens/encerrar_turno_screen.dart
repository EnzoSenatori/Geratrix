import 'package:flutter/material.dart';

import '../routes.dart';

// Tela de encerramento de turno e registro da passagem de plantão
class EncerrarTurnoScreen extends StatefulWidget {
  const EncerrarTurnoScreen({super.key});

  @override
  State<EncerrarTurnoScreen> createState() => _EncerrarTurnoScreenState();
}

class _EncerrarTurnoScreenState extends State<EncerrarTurnoScreen> {
  final _passagemPlantaoController = TextEditingController();

  @override
  void dispose() {
    _passagemPlantaoController.dispose();
    super.dispose();
  }

  // Finaliza o plantão e retorna para a tela inicial
  void _finalizarTurno() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Turno encerrado com sucesso!')),
    );
    // Remove todas as telas e retorna para a tela inicial de seleção de perfil
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.index,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Encerrar Turno'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  Text(
                    'Resumo do plantão',
                    style: textos.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Confira o balanço de tarefas executadas antes de finalizar.',
                    style: textos.bodyLarge?.copyWith(color: cores.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),

                  // Grid de Métricas Rápidas do Plantão
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: cores.primaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  '3',
                                  style: textos.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cores.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Concluídas',
                                  style: textos.labelMedium?.copyWith(
                                    color: cores.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Card(
                          color: cores.errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  '1',
                                  style: textos.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cores.error,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Não realizada',
                                  style: textos.labelMedium?.copyWith(
                                    color: cores.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Campo de Passagem de Plantão
                  Text(
                    'PASSAGEM DE PLANTÃO (MENSAGEM PARA A PRÓXIMA EQUIPE)',
                    style: textos.labelMedium?.copyWith(
                      color: cores.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passagemPlantaoController,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Relate intercorrências, recados para a próxima equipe...',
                    ),
                  ),
                ],
              ),
            ),

            // Rodapé Fixo
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: cores.error,
                  foregroundColor: cores.surface,
                ),
                onPressed: _finalizarTurno,
                icon: const Icon(Icons.power_settings_new_rounded),
                label: const Text('Confirmar e fechar turno'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}