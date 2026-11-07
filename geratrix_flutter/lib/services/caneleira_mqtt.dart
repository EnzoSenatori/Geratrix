import 'dart:convert';

import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

import '../models/estado_caneleira.dart';
import '../models/prescricao.dart';
import '../models/sessao_exercicio.dart';

// Endereço do broker para o navegador (WebSocket seguro) e tópicos do contrato
const _endereco = 'wss://z2f0d126.ala.eu-central-1.emqxsl.com/mqtt';
const _porta = 8084;
const _topicoCmd = 'imrea/g01/caneleira/cmd';
const _topicoEstado = 'imrea/g01/caneleira/estado';
const _topicoAck = 'imrea/g01/caneleira/ack';
const _topicoSessoes = 'imrea/g01/caneleira/sessao/+';
const _prefixoSessao = 'imrea/g01/caneleira/sessao/';

// Usuário e senha entram na hora de rodar: --dart-define=MQTT_SENHA=...
const _usuario = String.fromEnvironment(
  'MQTT_USUARIO',
  defaultValue: 'geratrix_g01',
);
const _senha = String.fromEnvironment('MQTT_SENHA');

// Conversa com a caneleira pelo broker; a tela recebe as novidades pelas funções do construtor
class CaneleiraMqtt {
  final void Function(bool conectado) onConexao;
  final void Function(EstadoCaneleira estado) onEstado;
  final void Function(SessaoExercicio sessao) onSessao;

  late final MqttBrowserClient _cliente;
  Prescricao? _pendente; // enviada, mas ainda não confirmada pela caneleira

  CaneleiraMqtt({
    required this.onConexao,
    required this.onEstado,
    required this.onSessao,
  });

  // Conecta ao broker, assina os tópicos e começa a ouvir as mensagens
  Future<void> conectar() async {
    final id = 'geratrix-${DateTime.now().millisecondsSinceEpoch}';
    _cliente = MqttBrowserClient.withPort(_endereco, id, _porta);
    _cliente.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
    _cliente.setProtocolV311();
    _cliente.keepAlivePeriod = 30;
    _cliente.autoReconnect = true; // a biblioteca reconecta e reassina sozinha
    _cliente.logging(on: false);
    _cliente.onConnected = () => onConexao(true);
    _cliente.onDisconnected = () => onConexao(false);
    _cliente.onAutoReconnect = () => onConexao(false);
    _cliente.onAutoReconnected = _aoReconectar;

    try {
      await _cliente.connect(_usuario, _senha);
    } catch (_) {
      _cliente.disconnect();
      onConexao(false);
      return;
    }

    _cliente.subscribe(_topicoEstado, MqttQos.atLeastOnce);
    _cliente.subscribe(_topicoSessoes, MqttQos.atLeastOnce);
    _cliente.updates!.listen(_tratarMensagens);
  }

  // Envia a prescrição pelo tópico cmd e a guarda até a caneleira confirmar
  void enviarPrescricao(Prescricao prescricao) {
    _pendente = prescricao;
    _publicar(_topicoCmd, prescricao.toJson());
  }

  // Avisa a caneleira de quantas séries da sessão o app já salvou
  void confirmar(String sid, int seriesRecebidas) {
    _publicar(_topicoAck, {'sid': sid, 'series_recebidas': seriesRecebidas});
  }

  // Encerra a conexão com o broker; a tela chama no dispose()
  void desconectar() {
    _cliente.onDisconnected = null; // a tela está fechando: não precisa mais ser avisada
    _cliente.disconnect();
  }

  // Separa as mensagens por tópico e entrega cada uma à tela já convertida em model
  void _tratarMensagens(List<MqttReceivedMessage<MqttMessage>> mensagens) {
    for (final mensagem in mensagens) {
      final publicacao = mensagem.payload as MqttPublishMessage;
      final texto = utf8.decode(publicacao.payload.message);
      if (texto.isEmpty) continue; // publicação vazia: a caneleira apagou a sessão retida

      try {
        final json = jsonDecode(texto) as Map<String, dynamic>;
        if (mensagem.topic == _topicoEstado) {
          final estado = EstadoCaneleira.fromJson(json);
          if (estado.sid == _pendente?.sid) _pendente = null; // a caneleira aceitou
          onEstado(estado);
        } else if (mensagem.topic.startsWith(_prefixoSessao)) {
          final sessao = SessaoExercicio.fromJson(json);
          if (sessao.sid == _pendente?.sid) _pendente = null;
          onSessao(sessao);
        }
      } catch (_) {
        // mensagem fora do formato do contrato: ignora, sem derrubar o app
      }
    }
  }

  // Depois de uma queda, reenvia a prescrição que a caneleira ainda não confirmou
  void _aoReconectar() {
    onConexao(true);
    final pendente = _pendente;
    if (pendente != null) _publicar(_topicoCmd, pendente.toJson());
  }

  // Publica um JSON com QoS 1; sem conexão, não faz nada
  void _publicar(String topico, Map<String, dynamic> dados) {
    if (_cliente.connectionStatus?.state != MqttConnectionState.connected) {
      return;
    }
    final construtor = MqttClientPayloadBuilder();
    construtor.addUTF8String(jsonEncode(dados));
    _cliente.publishMessage(topico, MqttQos.atLeastOnce, construtor.payload!);
  }
}