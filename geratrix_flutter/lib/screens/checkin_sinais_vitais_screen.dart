import 'package:flutter/material.dart';

import '../models/item_rotina.dart';
import '../routes.dart';
import '../services/api.dart';
import '../services/sessao_expirada.dart';
import 'erro_screen.dart';

// Tela de medição de sinais vitais e parâmetros de saúde com alerta em duas etapas
class CheckinSinaisVitaisScreen extends StatefulWidget {
  const CheckinSinaisVitaisScreen({super.key});

  @override
  State<CheckinSinaisVitaisScreen> createState() => _CheckinSinaisVitaisScreenState();
}

class _CheckinSinaisVitaisScreenState extends State<CheckinSinaisVitaisScreen> {
  final _valorController = TextEditingController();
  final _observacaoController = TextEditingController();

  bool _confirmandoForaDaFaixa = false;
  bool _enviando = false; // trava o botão enquanto a API responde
  String? _erro;

  @override
  void dispose() {
    _valorController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  // Envia a medição; o backend aplica a faixa e o alerta em duas etapas (US-13), como na rota HTML
  Future<void> _salvarMedicao(ItemRotina item) async {
    final mensageiro = ScaffoldMessenger.of(context);
    setState(() {
      _enviando = true;
      _erro = null;
    });

    try {
      final resultado = await Api.registrarMedicao(
        item.id,
        _valorController.text,
        _observacaoController.text,
        _confirmandoForaDaFaixa,
      );
      if (!mounted) return;

      // 1ª etapa: fora da faixa e ainda não confirmado; nada foi gravado
      if (!resultado.registrado) {
        setState(() {
          _confirmandoForaDaFaixa = true;
          _enviando = false;
        });
        return;
      }

      mensageiro.showSnackBar(SnackBar(
        content: Text(resultado.foraDaFaixa
            ? 'Medição fora da faixa registrada.'
            : 'Medição registrada com sucesso!'),
      ));
      Navigator.pop(context, true);
    } on SessaoExpirada {
      if (mounted) voltarParaPerfis(context);
    } on ErroApi catch (erro) {
      if (!mounted) return;
      if (erro.jaRegistrado) {
        mensageiro.showSnackBar(SnackBar(content: Text(erro.mensagem)));
        Navigator.pop(context, true);
        return;
      }
      setState(() {
        _erro = erro.mensagem; // ex.: "Informe o valor medido."
        _enviando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _enviando = false);
      mensageiro.showSnackBar(
        const SnackBar(content: Text('Não foi possível falar com o servidor. Tente novamente.')),
      );
    }
  }

  // Abre a tela de "não realizado" e repassa o resultado se confirmado
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

    final referenciaTexto = (item.faixaMin != null && item.faixaMax != null)
        ? 'Referência: ${item.faixaMin!.toStringAsFixed(item.faixaMin! % 1 == 0 ? 0 : 1)}–${item.faixaMax!.toStringAsFixed(item.faixaMax! % 1 == 0 ? 0 : 1)} ${item.unidade ?? ""}'
        : null;

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
                  const SizedBox(height: 8),
                  // Botão de atalho para abrir o Prontuário Rápido do Residente
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.residente,
                          arguments: item.residente,
                        );
                      },
                      icon: const Icon(Icons.badge_outlined, size: 20),
                      label: const Text('Ver prontuário'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Banner de alerta em duas etapas (fora da faixa)
                  if (_confirmandoForaDaFaixa) ...[
                    Card(
                      color: cores.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: cores.error, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Atenção: o valor informado está fora da faixa de referência esperada. Toque novamente para confirmar.',
                                style: textos.bodyMedium?.copyWith(
                                  color: cores.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Campo de valor da medição
                  TextField(
                    controller: _valorController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) {
                      if (_confirmandoForaDaFaixa || _erro != null) {
                        setState(() {
                          _confirmandoForaDaFaixa = false;
                          _erro = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: '${item.tipo} (${item.unidade ?? ""})',
                      helperText: referenciaTexto,
                      errorText: _erro,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Observação opcional
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
                      hintText: 'Ex: Residente em repouso há 15 min...',
                    ),
                  ),
                ],
              ),
            ),

            // Rodapé
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: _enviando ? null : () => _salvarMedicao(item),
                    icon: Icon(_confirmandoForaDaFaixa ? Icons.warning_rounded : Icons.check_circle_rounded),
                    label: Text(_confirmandoForaDaFaixa ? 'Confirmar valor fora da faixa' : 'Salvar medição'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _registrarNaoRealizado(item),
                    style: TextButton.styleFrom(
                      foregroundColor: cores.error,
                    ),
                    child: const Text('Não foi possível medir'),
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