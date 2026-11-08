import 'package:flutter/material.dart';

import '../models/item_rotina.dart';
import '../routes.dart';

// Tela de confirmação e registro de administração de medicamentos prescritos
class CheckinMedicamentoScreen extends StatefulWidget {
  const CheckinMedicamentoScreen({super.key});

  @override
  State<CheckinMedicamentoScreen> createState() => _CheckinMedicamentoScreenState();
}

class _CheckinMedicamentoScreenState extends State<CheckinMedicamentoScreen> {
  final _observacaoController = TextEditingController();
  // Confirmação de conferência de dosagem
  bool _dosagemConferida = false;

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  void _confirmarAdministracao() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Administração de medicamento registrada!')),
    );
    Navigator.pop(context);
  }

  void _registrarNaoRealizado(ItemRotina item) {
    Navigator.pushNamed(
      context,
      AppRoutes.naoRealizado,
      arguments: item,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    'Administração de medicação',
                    style: textos.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.residente} • Horário: ${item.horario}',
                    style: textos.bodyLarge?.copyWith(color: cores.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),

                  // Card de Detalhes da Prescrição
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.medication_rounded, color: cores.primary, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.tipo, // Ex: "Medicação: Losartana 50mg"
                                  style: textos.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Text(
                            'Instruções de administração:',
                            style: textos.labelMedium?.copyWith(
                              color: cores.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Via Oral • Tomar com água após o café da manhã.',
                            style: textos.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Checkbox de verificação de segurança (Double Check)
                  CheckboxListTile(
                    value: _dosagemConferida,
                    onChanged: (valor) {
                      setState(() {
                        _dosagemConferida = valor ?? false;
                      });
                    },
                    title: const Text('Confirmo a dosagem e o nome do residente na embalagem'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),

                  // Observações
                  Text(
                    'OBSERVAÇÃO (OPCIONAL)',
                    style: textos.labelMedium?.copyWith(
                      color: cores.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _observacaoController,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Recusou tomar com suco, ingeriu com água...',
                    ),
                  ),
                ],
              ),
            ),

            // Rodapé com botões de ação
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: _dosagemConferida ? _confirmarAdministracao : null,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Confirmar administração'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _registrarNaoRealizado(item),
                    style: TextButton.styleFrom(
                      foregroundColor: cores.error,
                    ),
                    child: const Text('Não foi possível administrar'),
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