import 'package:flutter/material.dart';

import '../models/estado_caneleira.dart';
import '../models/prescricao.dart';
import '../models/sessao_exercicio.dart';
import '../services/caneleira_mqtt.dart';
import '../widgets/caneleira_card.dart';
import '../widgets/serie_tile.dart';

// Prescrição definida pelo gestor; por enquanto fixa e em memória, com valores curtos para teste
const _series = 2;
const _reps = 10;
const _admMin = 60.0;
const _velMax = 150.0;
const _descanso = 10;

// Registro de exercício com a caneleira: envia a prescrição e acompanha as séries
class ExercicioScreen extends StatefulWidget {
  const ExercicioScreen({super.key});

  @override
  State<ExercicioScreen> createState() => _ExercicioScreenState();
}

class _ExercicioScreenState extends State<ExercicioScreen> {
  late final CaneleiraMqtt _mqtt;
  bool _conectado = false;
  EstadoCaneleira _estado = const EstadoCaneleira(online: false);
  final _sessoes = <String, SessaoExercicio>{}; // por sid, na ordem em que chegaram
  String? _sidAtual; // sessão iniciada por esta tela
  DateTime? _enviadaEm;

  @override
  void initState() {
    super.initState();
    _mqtt = CaneleiraMqtt(
      onConexao: (conectado) {
        if (!mounted) return;
        setState(() => _conectado = conectado);
      },
      onEstado: (estado) {
        if (!mounted) return;
        setState(() => _estado = estado);
      },
      onSessao: _receberSessao,
    );
    _mqtt.conectar();
  }

  @override
  void dispose() {
    _mqtt.desconectar();
    super.dispose();
  }

  // Guarda a sessão recebida e só depois confirma à caneleira, como pede o contrato
  void _receberSessao(SessaoExercicio sessao) {
    if (!mounted) return;
    setState(() => _sessoes[sessao.sid] = sessao);
    _mqtt.confirmar(sessao.sid, sessao.series.length);
  }

  // Cria a prescrição com um sid novo e a envia à caneleira
  void _enviarPrescricao() {
    final prescricao = Prescricao(
      sid: 's${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}',
      series: _series,
      reps: _reps,
      admMin: _admMin,
      velMax: _velMax,
      descanso: _descanso,
    );
    _mqtt.enviarPrescricao(prescricao);
    setState(() {
      _sidAtual = prescricao.sid;
      _enviadaEm = DateTime.now();
    });
  }

  // Formata a hora como no mockup ("10:02")
  String _formatarHora(DateTime hora) {
    final h = hora.hour.toString().padLeft(2, '0');
    final m = hora.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // Monta um número da prescrição com o rótulo abaixo, como os painéis do guia visual
  Widget _montarNumero(String valor, String rotulo) {
    final textos = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            valor,
            style: textos.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(rotulo, style: textos.bodySmall),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final tituloSecao = textos.titleLarge?.copyWith(fontWeight: FontWeight.w700);
    final sessaoAtual = _sessoes[_sidAtual];
    final enviadaEm = _enviadaEm;
    final podeEnviar = _conectado &&
        _estado.online &&
        (_sidAtual == null || sessaoAtual?.concluida == true);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          children: [
            Text(
              'Registrar exercício',
              style: textos.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Extensão de joelho com a caneleira',
              style: textos.bodyLarge?.copyWith(color: cores.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            CaneleiraCard(estado: _estado, conectado: _conectado),
            const SizedBox(height: 24),
            Text('Prescrição', style: tituloSecao),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _montarNumero('$_series', 'séries'),
                        _montarNumero('$_reps', 'repetições'),
                        _montarNumero('${_admMin.toStringAsFixed(0)}°', 'ADM mínima'),
                        _montarNumero('$_descanso s', 'descanso'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      enviadaEm == null
                          ? 'Definida pelo gestor'
                          : 'Enviada à caneleira às ${_formatarHora(enviadaEm)}',
                      style: textos.bodySmall?.copyWith(
                        color: cores.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: podeEnviar ? _enviarPrescricao : null,
              child: const Text('Enviar à caneleira'),
            ),
            if (_sidAtual != null) ...[
              const SizedBox(height: 24),
              Text('Séries', style: tituloSecao),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    for (final serie in sessaoAtual?.series ?? const [])
                      SerieTile(serie: serie),
                    if (sessaoAtual?.concluida != true)
                      const ListTile(
                        title: Text('Aguardando resumo da caneleira...'),
                      ),
                  ],
                ),
              ),
            ],
            for (final sessao in _sessoes.values)
              if (sessao.sid != _sidAtual) ...[
                const SizedBox(height: 24),
                Text('Sessão iniciada sem o app', style: tituloSecao),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      for (final serie in sessao.series) SerieTile(serie: serie),
                    ],
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}