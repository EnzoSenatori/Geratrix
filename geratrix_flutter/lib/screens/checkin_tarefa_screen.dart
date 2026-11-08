import 'package:flutter/material.dart';

import '../models/item_rotina.dart';
import '../routes.dart';

// Tela de confirmação de uma tarefa comum da rotina (ex: Banho, Lanche)
class CheckinTarefaScreen extends StatefulWidget {
  const CheckinTarefaScreen({super.key});

  @override
  State<CheckinTarefaScreen> createState() => _CheckinTarefaScreenState();
}

class _CheckinTarefaScreenState extends State<CheckinTarefaScreen> {
  // Controlador para o campo de texto de observações
  final _observacaoController = TextEditingController();

  @override
  void dispose() {
    // É fundamental descartar o controlador quando a tela for fechada para liberar memória
    _observacaoController.dispose();
    super.dispose();
  }

  // Ação de confirmar o check-in
  void _registrarTarefa() {
    // Aqui no futuro enviaremos _observacaoController.text para a API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tarefa registrada com sucesso!')),
    );
    // Remove a tela atual e volta para a lista do plantão
    Navigator.pop(context);
  }

  // Ação de apontar que a tarefa não foi realizada
  void _registrarNaoRealizado() {
    // Resgata o item da rota atual para repassar para a próxima tela
    final item = ModalRoute.of(context)!.settings.arguments as ItemRotina;
    
    Navigator.pushNamed(
      context, 
      AppRoutes.naoRealizado, 
      arguments: item,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Resgata o item específico que foi clicado na tela de Lista
    final item = ModalRoute.of(context)!.settings.arguments as ItemRotina;
    
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    
    // Define o estilo visual da tag (Chip) baseado no status
    final isAtrasado = item.status == 'atrasado';
    final corStatus = isAtrasado ? cores.error : cores.onSurfaceVariant;
    final fundoStatus = isAtrasado ? cores.errorContainer : cores.surfaceContainerHighest;
    final iconeStatus = isAtrasado ? Icons.warning_rounded : Icons.schedule_rounded;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context), // Volta para a lista sem registrar
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Usamos Expanded para a área rolável, empurrando o rodapé para baixo
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  Text(
                    'Registrar tarefa',
                    style: textos.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Cabeçalho da tarefa com o status em destaque
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: cores.primaryContainer,
                        foregroundColor: cores.onPrimaryContainer,
                        radius: 24,
                        child: const Icon(Icons.assignment_turned_in_rounded),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.tipo,
                              style: textos.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              item.residente,
                              style: textos.bodyMedium?.copyWith(color: cores.onSurfaceVariant),
                            ),
                            const SizedBox(height: 8),
                            // Tag indicadora de horário/atraso
                            Chip(
                              avatar: Icon(iconeStatus, color: corStatus, size: 16),
                              label: Text(
                                '${item.horario} • ${isAtrasado ? 'Atrasado' : 'Pendente'}',
                              ),
                              labelStyle: TextStyle(
                                color: corStatus,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              backgroundColor: fundoStatus,
                              side: BorderSide.none,
                              shape: const StadiumBorder(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Campo opcional de observação
                  Text(
                    'Observação (opcional)',
                    style: textos.labelMedium?.copyWith(
                      color: cores.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _observacaoController,
                    maxLines: 3, // Permite campo mais altinho para texto longo
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Detalhes relevantes sobre a execução...',
                    ),
                  ),
                ],
              ),
            ),
            
            // Rodapé fixo com as ações
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: _registrarTarefa,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Registrar'),
                  ),
                  const SizedBox(height: 8),
                  // Botão terciário (TextButton) para não competir com a ação principal
                  TextButton(
                    onPressed: _registrarNaoRealizado,
                    style: TextButton.styleFrom(
                      foregroundColor: cores.error, // Vermelho indicando uma exceção/alerta
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