import 'package:flutter/material.dart';

import '../models/item_rotina.dart';
import '../services/api.dart';
import '../services/registro.dart';
import 'erro_screen.dart';

// Motivos aceitos pelo backend (RN-04): chave enviada à API -> texto mostrado no chip
const _motivosNaoRealizado = {
  'recusa': 'Recusa do residente',
  'dormindo': 'Residente dormindo',
  'material-indisponivel': 'Material indisponível',
  'emergencia': 'Emergência',
};

// Tela de registro de exceção / não realização de tarefa
class NaoRealizadoScreen extends StatefulWidget {
  const NaoRealizadoScreen({super.key});

  @override
  State<NaoRealizadoScreen> createState() => _NaoRealizadoScreenState();
}

class _NaoRealizadoScreenState extends State<NaoRealizadoScreen> {
  String? _motivoSelecionado; // chave do motivo (ex.: 'dormindo')
  bool _enviando = false; // trava o botão enquanto a API grava
  final _justificativaController = TextEditingController();

  @override
  void dispose() {
    _justificativaController.dispose();
    super.dispose();
  }

  // Grava o não realizado no banco e devolve true para a tela anterior, que volta à lista recarregando
  Future<void> _confirmar(ItemRotina item, String motivo) async {
    setState(() => _enviando = true);
    final fechar = await enviarRegistro(
      context,
      () => Api.registrarNaoRealizado(item.id, motivo, _justificativaController.text),
      'Registro de não realização gravado!',
    );
    if (!mounted) return;
    if (fechar) {
      Navigator.pop(context, true);
    } else {
      setState(() => _enviando = false);
    }
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
                    children: _motivosNaoRealizado.entries.map((motivo) {
                      final isSelecionado = _motivoSelecionado == motivo.key;
                      return ChoiceChip(
                        label: Text(motivo.value),
                        selected: isSelecionado,
                        onSelected: (selecionado) {
                          setState(() {
                            _motivoSelecionado = selecionado ? motivo.key : null;
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
                onPressed: _motivoSelecionado != null && !_enviando
                    ? () => _confirmar(item, _motivoSelecionado!)
                    : null,
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