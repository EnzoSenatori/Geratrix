import 'package:flutter/material.dart';

import '../models/item_rotina.dart';
import '../routes.dart';

// Tela para registrar o motivo de uma tarefa não ter sido executada
class NaoRealizadoScreen extends StatefulWidget {
  const NaoRealizadoScreen({super.key});

  @override
  State<NaoRealizadoScreen> createState() => _NaoRealizadoScreenState();
}

class _NaoRealizadoScreenState extends State<NaoRealizadoScreen> {
  // Guarda qual botão de motivo foi clicado
  String? _motivoSelecionado;
  // Controlador para o texto de justificativa
  final _justificativaController = TextEditingController();

  // Lista padrão de motivos para facilitar o preenchimento (Guia Visual)
  final _motivos = [
    'Recusa do residente',
    'Dormindo',
    'Ausência (saída/consulta)',
    'Agitação / Comportamento',
    'Outro',
  ];

  @override
  void dispose() {
    _justificativaController.dispose();
    super.dispose();
  }

  void _confirmar() {
    // Futuramente, enviará _motivoSelecionado e _justificativaController.text para a API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro salvo com sucesso!')),
    );
    // Navega de volta até encontrar a tela da Lista, removendo as telas de check-in do caminho
    Navigator.popUntil(context, ModalRoute.withName(AppRoutes.lista));
  }

  @override
  Widget build(BuildContext context) {
    // Resgata a tarefa enviada pela tela anterior
    final item = ModalRoute.of(context)!.settings.arguments as ItemRotina;
    
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
                    'Não realizado',
                    style: textos.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      letterSpacing: -0.5,
                      color: cores.error, // Destaque em vermelho (alerta de falha)
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item.tipo} • ${item.residente}',
                    style: textos.bodyLarge?.copyWith(color: cores.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  
                  Text(
                    'SELECIONE O MOTIVO PRINCIPAL',
                    style: textos.labelMedium?.copyWith(
                      color: cores.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Wrap permite colocar os chips em linha e quebrar para a próxima quando faltar espaço
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _motivos.map((motivo) {
                      final isSelecionado = _motivoSelecionado == motivo;
                      return ChoiceChip(
                        label: Text(motivo),
                        selected: isSelecionado,
                        onSelected: (selecionado) {
                          setState(() {
                            // Se clicar num selecionado, ele desmarca (null)
                            _motivoSelecionado = selecionado ? motivo : null;
                          });
                        },
                        backgroundColor: cores.surfaceContainerHighest,
                        selectedColor: cores.errorContainer, // Fundo vermelho-claro quando ativo
                        labelStyle: TextStyle(
                          color: isSelecionado ? cores.error : cores.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        shape: const StadiumBorder(),
                        side: BorderSide.none,
                        showCheckmark: false, // Esconde o ícone "check" para manter o visual limpo
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    'JUSTIFICATIVA / DETALHES',
                    style: textos.labelMedium?.copyWith(
                      color: cores.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _justificativaController,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Descreva o que aconteceu...',
                    ),
                  ),
                ],
              ),
            ),
            
            // Rodapé fixo
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FilledButton(
                // Força as cores do botão destrutivo do Guia Visual
                style: FilledButton.styleFrom(
                  backgroundColor: cores.error,
                  foregroundColor: cores.surface, // Branco
                ),
                // O botão só fica habilitado se algum motivo for selecionado
                onPressed: _motivoSelecionado != null ? _confirmar : null,
                child: const Text('Confirmar não realização'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}