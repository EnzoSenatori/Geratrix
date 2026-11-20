import 'package:flutter/material.dart';

import '../models/item_rotina.dart';
import '../routes.dart';
import 'erro_screen.dart';

// Tela de Encerramento de Turno: resumo das atividades, pendências e passagem de plantão
class EncerrarTurnoScreen extends StatefulWidget {
  const EncerrarTurnoScreen({super.key});

  @override
  State<EncerrarTurnoScreen> createState() => _EncerrarTurnoScreenState();
}

class _EncerrarTurnoScreenState extends State<EncerrarTurnoScreen> {
  final _passagemController = TextEditingController();

  @override
  void dispose() {
    _passagemController.dispose();
    super.dispose();
  }

  void _encerrarPlantao() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plantão encerrado com sucesso!')),
    );
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.index,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final itens = ModalRoute.of(context)?.settings.arguments as List<ItemRotina>?;

    // Proteção contra F5 / acesso direto sem a lista de tarefas
    if (itens == null) {
      return const ErroScreen(
        mensagem: 'Esta tela abre a partir do início do app.',
      );
    }

    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    final concluidas = itens.where((i) => i.status == 'feito').length;
    final naoRealizadas = itens.where((i) => i.status == 'nao_realizado').length;
    final pendentes = itens.where((i) => !i.registrado).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Encerramento de Turno'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  Text(
                    'Balanço do plantão',
                    style: textos.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cards com métricas consolidadas
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
                                  '$concluidas',
                                  style: textos.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cores.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Concluídas',
                                  style: textos.bodyMedium?.copyWith(
                                    color: cores.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          color: cores.errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  '$naoRealizadas',
                                  style: textos.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cores.error,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Não realizadas',
                                  style: textos.bodyMedium?.copyWith(
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

                  // Seção de Pendências (se houver)
                  Text(
                    'PENDÊNCIAS DO TURNO',
                    style: textos.labelMedium?.copyWith(
                      color: cores.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (pendentes.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Nenhuma pendência remanescente.',
                          style: textos.bodyMedium?.copyWith(
                            color: cores.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: pendentes.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                '• ${item.tipo} — ${item.residente.nome} (${item.horario})',
                                style: textos.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Observações para a passagem de plantão
                  Text(
                    'PASSAGEM DE PLANTÃO',
                    style: textos.labelMedium?.copyWith(
                      color: cores.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passagemController,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Relate acontecimentos importantes para a próxima equipe...',
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Rodapé com o botão para finalizar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FilledButton.icon(
                onPressed: _encerrarPlantao,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Finalizar e fechar turno'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}