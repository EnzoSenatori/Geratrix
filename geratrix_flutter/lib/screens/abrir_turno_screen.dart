import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/api.dart';
import '../services/sessao_expirada.dart';

// Tela de Abertura de Turno: exibe os dados do turno anterior vindos do backend (/api/turno/abrir)
class AbrirTurnoScreen extends StatefulWidget {
  const AbrirTurnoScreen({super.key});

  @override
  State<AbrirTurnoScreen> createState() => _AbrirTurnoScreenState();
}

class _AbrirTurnoScreenState extends State<AbrirTurnoScreen> {
  Map<String, dynamic>? _dados;
  bool _falhou = false;
  bool _iniciando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  // Busca alertas, passagem e pendências do último turno; sem sessão, volta para os perfis
  Future<void> _carregar() async {
    setState(() {
      _dados = null;
      _falhou = false;
    });
    try {
      final dados = await Api.dadosAbertura();
      if (mounted) setState(() => _dados = dados);
    } on SessaoExpirada {
      if (mounted) voltarParaPerfis(context);
    } catch (_) {
      if (mounted) setState(() => _falhou = true);
    }
  }

  // Abre o turno no backend e segue para a lista do agora
  Future<void> _iniciarPlantao() async {
    setState(() => _iniciando = true);
    try {
      await Api.abrirTurno();
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.lista);
    } on SessaoExpirada {
      if (mounted) voltarParaPerfis(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _iniciando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o turno. Tente novamente.')),
      );
    }
  }

  // Volta para a tela anterior; aberta por F5, não há anterior e vai para os perfis
  void _voltar() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.index, (rota) => false);
    }
  }

  // Formata números sem decimais desnecessários (165.0 -> 165, 37.8 -> 37,8), como o filtro "numero" do Jinja
  String _numero(num valor) {
    if (valor == valor.roundToDouble()) return valor.toInt().toString();
    return valor.toString().replaceAll('.', ',');
  }

  // Monta o texto de um alerta: medição fora da faixa ou item não realizado
  String _textoAlerta(Map<String, dynamic> alerta) {
    final base = '${alerta['tipo_nome']} — ${alerta['residente_nome']}';
    if (alerta['status'] == 'nao_realizado') {
      return '$base (Não realizado: ${alerta['motivo'] ?? 'sem motivo'})';
    }
    final valor = alerta['valor'] as num?;
    if (valor == null) return base;
    final unidade = alerta['unidade'] as String?;
    return '$base (${_numero(valor)}${unidade == null ? '' : ' $unidade'})';
  }

  // Pega só o HH:MM de "AAAA-MM-DD HH:MM:SS"
  String _hora(String? dataHora) {
    if (dataHora == null || dataHora.length < 16) return dataHora ?? '';
    return dataHora.substring(11, 16);
  }

  Widget _titulo(String texto, ColorScheme cores, TextTheme textos) {
    return Text(
      texto,
      style: textos.labelMedium?.copyWith(
        color: cores.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }

  // Conteúdo com os dados da API: turno anterior, alertas, passagem e pendências
  List<Widget> _montarConteudo(Map<String, dynamic> dados, ColorScheme cores, TextTheme textos) {
    final ultimoTurno = dados['ultimo_turno'] as Map<String, dynamic>?;
    final alertas = (dados['alertas'] as List<dynamic>).cast<Map<String, dynamic>>();
    final pendencias = (dados['pendencias'] as List<dynamic>).cast<String>();
    final passagem = (ultimoTurno?['passagem'] as String?)?.trim() ?? '';

    return [
      Text(
        'Turno anterior',
        style: textos.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 28,
          letterSpacing: -0.5,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        ultimoTurno == null
            ? 'Nenhum turno encerrado ainda.'
            : 'Encerrado às ${_hora(ultimoTurno['encerrado_em'] as String?)} por ${ultimoTurno['cuidador_nome']}',
        style: textos.bodyLarge?.copyWith(color: cores.onSurfaceVariant),
      ),
      const SizedBox(height: 24),

      // Seção de Alertas do Turno Anterior
      _titulo('ALERTAS E OCORRÊNCIAS', cores, textos),
      const SizedBox(height: 8),
      Card(
        color: alertas.isEmpty ? null : cores.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: alertas.isEmpty
              ? Text('Nenhum alerta no turno anterior.', style: textos.bodyMedium)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < alertas.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            alertas[i]['status'] == 'nao_realizado'
                                ? Icons.info_outline_rounded
                                : Icons.warning_rounded,
                            color: cores.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _textoAlerta(alertas[i]),
                              style: textos.bodyMedium?.copyWith(
                                color: cores.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
        ),
      ),
      const SizedBox(height: 24),

      // Seção de Passagem de Plantão
      _titulo('PASSAGEM DE PLANTÃO', cores, textos),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            passagem.isEmpty ? 'Sem passagem registrada.' : passagem,
            style: textos.bodyMedium,
          ),
        ),
      ),
      const SizedBox(height: 24),

      // Seção de Pendências
      _titulo('PENDÊNCIAS DO TURNO ANTERIOR', cores, textos),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pendencias.isEmpty) Text('Nenhuma pendência.', style: textos.bodyMedium),
              for (final pendencia in pendencias)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    pendencia,
                    style: textos.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final dados = _dados;
    final cuidador = dados?['cuidador'] as Map<String, dynamic>?;

    Widget corpo;
    if (_falhou) {
      corpo = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Não foi possível carregar o turno anterior.',
              style: textos.bodyLarge?.copyWith(color: cores.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _carregar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar de novo'),
            ),
          ],
        ),
      );
    } else if (dados == null) {
      corpo = const Center(child: CircularProgressIndicator());
    } else {
      corpo = ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: _montarConteudo(dados, cores, textos),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _voltar,
        ),
        title: const Text('Abertura de Turno'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: corpo),

            // Botão de início de plantão
            if (dados != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: FilledButton.icon(
                  onPressed: _iniciando ? null : _iniciarPlantao,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text('Iniciar plantão (${cuidador?['nome'] ?? 'Cuidador'})'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
