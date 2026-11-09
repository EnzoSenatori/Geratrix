import 'package:flutter/material.dart';

import '../models/item_rotina.dart';
import 'erro_screen.dart';

// Motivos homologados no backend conforme RN-04
const _motivosNaoRealizado = [
  'Recusa do residente',
  'Residente dormindo',
  'Material indisponível',
  'Emergência',
];

// Tela de registro de exceção / não realização de tarefa
class NaoRealizadoScreen extends StatefulWidget {
  const NaoRealizadoScreen({super.key});

  @override
  State<NaoRealizadoScreen> createState() => _NaoRealizadoScreenState();
}

class _NaoRealizadoScreenState extends State<NaoRealizadoScreen> {
  String? _motivoSelecionado;
  final _justificativaController = TextEditingController();

  @override
  void dispose() {
    _justificativaController.dispose();
    super.dispose();
  }

  // Devolve o resultado 'nao_realizado' para a tela anterior
  void _confirmar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro de não realização gravado!')),
    );
    Navigator.pop(context, 'nao_realizado');
  }

  @override
  Widget build(BuildContext context) {
    final item = ModalRoute.of(context)?.settings.arguments as ItemRotina?;

    // Proteção contra F5 / acesso direto sem item de rotina
    if (item == null) {
      return const ErroScreen(
        mensagem: 'Esta tela abre a partir do início do app.',
      );
    }

    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  Text(
                    'Não realização de tarefa',
                    style: textos.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.tipo} • ${item.residente.nome}',
                    style: textos.bodyLarge?.copyWith(color: cores.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'SELECIONE O MOTIVO (OBRIGATÓRIO)',
                    style: textos.labelMedium?.copyWith(
                      color: cores.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Chips com os motivos da RN-04
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _motivosNaoRealizado.map((motivo) {
                      final isSelecionado = _motivoSelecionado == motivo;
                      return ChoiceChip(
                        label: Text(motivo),
                        selected: isSelecionado,
                        onSelected: (selecionado) {
                          setState(() {
                            _motivoSelecionado = selecionado ? motivo : null;
                          });
                        },
                        backgroundColor: cores.surfaceContainerHighest,
                        selectedColor: cores.errorContainer,
                        labelStyle: TextStyle(
                          color: isSelecionado ? cores.error : cores.onSurface,
                          fontWeight: isSelecionado ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide.none,
                        shape: const StadiumBorder(),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'JUSTIFICATIVA COMPLEMENTAR (OPCIONAL)',
                    style: textos.labelMedium?.copyWith(
                      color: cores.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _justificativaController,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Adicione detalhes sobre a situação...',
                    ),
                  ),
                ],
              ),
            ),

            // Rodapé com o botão de confirmação
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: cores.error,
                  foregroundColor: cores.surface,
                ),
                onPressed: _motivoSelecionado != null ? _confirmar : null,
                icon: const Icon(Icons.warning_amber_rounded),
                label: const Text('Confirmar registro'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}