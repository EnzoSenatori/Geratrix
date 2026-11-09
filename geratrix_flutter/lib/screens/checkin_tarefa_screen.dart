import 'package:flutter/material.dart';

import '../models/item_rotina.dart';
import '../routes.dart';
import 'erro_screen.dart';

// Tela de Check-in genérico para tarefas cotidianas
class CheckinTarefaScreen extends StatefulWidget {
  const CheckinTarefaScreen({super.key});

  @override
  State<CheckinTarefaScreen> createState() => _CheckinTarefaScreenState();
}

class _CheckinTarefaScreenState extends State<CheckinTarefaScreen> {
  final _observacaoController = TextEditingController();

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  // Registra a conclusão da tarefa e devolve 'feito' para a lista
  void _salvarTarefa() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tarefa registrada com sucesso!')),
    );
    Navigator.pop(context, 'feito');
  }

  // Abre a tela de "não realizado" e repassa o resultado para a lista se confirmado
  Future<void> _registrarNaoRealizado(ItemRotina item) async {
    final resultado = await Navigator.pushNamed(
      context,
      AppRoutes.naoRealizado,
      arguments: item,
    );
    if (!mounted || resultado == null) return;
    Navigator.pop(context, resultado);
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
                    item.tipo,
                    style: textos.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.residente.nome} • Horário: ${item.horario}',
                    style: textos.bodyLarge?.copyWith(color: cores.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'OBSERVAÇÕES DA TAREFA',
                    style: textos.labelMedium?.copyWith(
                      color: cores.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _observacaoController,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Descreva como foi a execução da tarefa...',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: _salvarTarefa,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Concluir tarefa'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _registrarNaoRealizado(item),
                    style: TextButton.styleFrom(
                      foregroundColor: cores.error,
                    ),
                    child: const Text('Não foi possível realizar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}