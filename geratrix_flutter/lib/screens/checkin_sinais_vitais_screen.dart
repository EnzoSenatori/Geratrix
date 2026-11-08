import 'package:flutter/material.dart';

import '../models/item_rotina.dart';
import '../routes.dart';

// Tela especializada para registro de sinais vitais (PA, Glicemia, Temp, FC)
class CheckinSinaisVitaisScreen extends StatefulWidget {
  const CheckinSinaisVitaisScreen({super.key});

  @override
  State<CheckinSinaisVitaisScreen> createState() => _CheckinSinaisVitaisScreenState();
}

class _CheckinSinaisVitaisScreenState extends State<CheckinSinaisVitaisScreen> {
  // Controladores para os campos numéricos de medição
  final _sistolicaController = TextEditingController();
  final _diastolicaController = TextEditingController();
  final _glicemiaController = TextEditingController();
  final _temperaturaController = TextEditingController();
  final _bpmController = TextEditingController();
  final _observacaoController = TextEditingController();

  // Estado para controle de alerta de alteração nos parâmetros
  bool _temAlertaParametros = false;

  @override
  void dispose() {
    // Descarte obrigatório de todos os controladores para gestão de memória
    _sistolicaController.dispose();
    _diastolicaController.dispose();
    _glicemiaController.dispose();
    _temperaturaController.dispose();
    _bpmController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  // Avalia se os valores digitados fogem da faixa de normalidade
  void _avaliarParametros() {
    final sistolica = int.tryParse(_sistolicaController.text) ?? 0;
    final glicemia = int.tryParse(_glicemiaController.text) ?? 0;

    setState(() {
      // Exemplo de regra clínica: PA Systolic > 140 ou Glicemia > 180 aciona alerta visual
      _temAlertaParametros = (sistolica >= 140) || (glicemia >= 180);
    });
  }

  // Confirma o registro dos sinais vitais
  void _salvarMedicao() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sinais vitais registrados com sucesso!')),
    );
    Navigator.pop(context);
  }

  // Encaminha para o fluxo de não realização
  void _registrarNaoRealizado(ItemRotina item) {
    Navigator.pushNamed(
      context,
      AppRoutes.naoRealizado,
      arguments: item,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Resgata o item repassado pela lista
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
                    'Aferição de sinais vitais',
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

                  // Banner dinâmico acionado quando há parâmetros alterados
                  if (_temAlertaParametros) ...[
                    Card(
                      color: cores.errorContainer,
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.warning_rounded, color: cores.error, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Atenção: Parâmetro(s) fora da faixa de referência normal.',
                                style: textos.bodyMedium?.copyWith(
                                  color: cores.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Seção: Pressão Arterial
                  Text(
                    'PRESSÃO ARTERIAL (mmHg)',
                    style: textos.labelMedium?.copyWith(
                      color: cores.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _sistolicaController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _avaliarParametros(),
                          decoration: const InputDecoration(
                            labelText: 'Sistólica (MAX)',
                            hintText: 'Ex: 120',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _diastolicaController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _avaliarParametros(),
                          decoration: const InputDecoration(
                            labelText: 'Diastólica (MIN)',
                            hintText: 'Ex: 80',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Seção: Glicemia e Temperatura
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GLICEMIA (mg/dL)',
                              style: textos.labelMedium?.copyWith(
                                color: cores.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _glicemiaController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => _avaliarParametros(),
                              decoration: const InputDecoration(
                                hintText: 'Ex: 99',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TEMP. (°C)',
                              style: textos.labelMedium?.copyWith(
                                color: cores.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _temperaturaController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                hintText: 'Ex: 36.5',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Seção: Frequência Cardíaca
                  Text(
                    'FREQUÊNCIA CARDÍACA (BPM)',
                    style: textos.labelMedium?.copyWith(
                      color: cores.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bpmController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Ex: 72',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campo de Observações Gerais
                  Text(
                    'OBSERVAÇÕES CLÍNICAS',
                    style: textos.labelMedium?.copyWith(
                      color: cores.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _observacaoController,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Intercorrências ou comportamento durante o exame...',
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Rodapé com ações principais
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: _salvarMedicao,
                    icon: const Icon(Icons.favorite_rounded),
                    label: const Text('Salvar medição'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _registrarNaoRealizado(item),
                    style: TextButton.styleFrom(
                      foregroundColor: cores.error,
                    ),
                    child: const Text('Não foi possível aferir'),
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