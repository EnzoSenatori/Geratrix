import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/cuidador.dart';
import '../models/item_rotina.dart';

// Lançada quando o backend responde 401: não há sessão (ou ela expirou) e o app volta para os perfis
class SessaoExpirada implements Exception {}

// Erro de regra vindo do backend (PIN incorreto, bloqueio, dados inválidos), com a mensagem pronta para mostrar
class ErroApi implements Exception {
  final int status;
  final String mensagem;

  const ErroApi(this.status, this.mensagem);

  // 429 = cuidador bloqueado por excesso de tentativas (OWASP A07)
  bool get bloqueado => status == 429;

  // 409 = item já registrado hoje (por este ou outro cuidador); a lista precisa recarregar
  bool get jaRegistrado => status == 409;
}

// Resposta do registro de medição: gravado, ou parado na 1ª etapa pedindo confirmação do valor fora da faixa
class ResultadoMedicao {
  final bool registrado;
  final bool foraDaFaixa;

  const ResultadoMedicao({required this.registrado, required this.foraDaFaixa});
}

// Resposta do login: quem entrou e se já existe um turno aberto para ele
class ResultadoLogin {
  final Cuidador cuidador;
  final bool turnoAberto;

  const ResultadoLogin(this.cuidador, this.turnoAberto);
}

// Conversa com a API do Flask no mesmo endereço do app (/app e /api na mesma origem, sem CORS).
// O cookie de sessão é HttpOnly: o navegador envia sozinho e o Dart nunca tem acesso a ele.
class Api {
  Api._(); // não pode ser instanciada

  static const _json = {'Content-Type': 'application/json'};

  // Monta a URL da API a partir do endereço da página (ex.: http://localhost:5000/api/lista)
  static Uri _url(String caminho) => Uri.base.resolve(caminho);

  // Confere o status da resposta e devolve o corpo já decodificado
  static dynamic _tratar(http.Response resposta) {
    final texto = utf8.decode(resposta.bodyBytes);
    final corpo = texto.isEmpty ? null : jsonDecode(texto);

    if (resposta.statusCode == 401) throw SessaoExpirada();
    if (resposta.statusCode >= 400) {
      final mensagem = corpo is Map && corpo['erro'] is String
          ? corpo['erro'] as String
          : 'Erro no servidor (HTTP ${resposta.statusCode}).';
      throw ErroApi(resposta.statusCode, mensagem);
    }
    return corpo;
  }

  // GET /api/cuidadores: cuidadores ativos para a tela de perfis
  static Future<List<Cuidador>> listarCuidadores() async {
    final corpo = _tratar(await http.get(_url('/api/cuidadores'))) as List<dynamic>;
    return corpo.map((c) => Cuidador.deJson(c as Map<String, dynamic>)).toList();
  }

  // POST /api/login: o backend confere o PIN (hash) e controla o limite de tentativas
  static Future<ResultadoLogin> entrar(int cuidadorId, String pin) async {
    final resposta = await http.post(
      _url('/api/login'),
      headers: _json,
      body: jsonEncode({'cuidador_id': cuidadorId, 'pin': pin}),
    );
    final corpo = _tratar(resposta) as Map<String, dynamic>;
    return ResultadoLogin(
      Cuidador.deJson(corpo['cuidador'] as Map<String, dynamic>),
      corpo['turno_aberto'] as bool,
    );
  }

  // GET /api/turno/abrir: dados do turno anterior (alertas, passagem e pendências)
  static Future<Map<String, dynamic>> dadosAbertura() async {
    return _tratar(await http.get(_url('/api/turno/abrir'))) as Map<String, dynamic>;
  }

  // POST /api/turno/abrir: abre o turno (ou reaproveita o que já está aberto)
  static Future<void> abrirTurno() async {
    _tratar(await http.post(_url('/api/turno/abrir'), headers: _json, body: '{}'));
  }

  // GET /api/lista: itens do turno com o status calculado pelo backend
  static Future<List<ItemRotina>> itensDoTurno() async {
    final corpo = _tratar(await http.get(_url('/api/lista'))) as Map<String, dynamic>;
    final itens = corpo['itens'] as List<dynamic>;
    return itens.map((i) => ItemRotina.deJson(i as Map<String, dynamic>)).toList();
  }

  // Caminho do item na API; o id vem da própria API, mas vai codificado por segurança
  static String _item(String itemId) => '/api/checkin/${Uri.encodeComponent(itemId)}';

  // POST /api/checkin/<id>: tarefa realizada (também medicação e exercício, que no banco são tarefas)
  static Future<void> registrarTarefa(String itemId, String observacao) async {
    _tratar(await http.post(
      _url(_item(itemId)),
      headers: _json,
      body: jsonEncode({'observacao': observacao}),
    ));
  }

  // POST /api/checkin/<id>/medicao: o backend decide se o valor está fora da faixa e pede confirmação
  static Future<ResultadoMedicao> registrarMedicao(
    String itemId,
    String valor,
    String observacao,
    bool confirmado,
  ) async {
    final corpo = _tratar(await http.post(
      _url('${_item(itemId)}/medicao'),
      headers: _json,
      body: jsonEncode({'valor': valor, 'observacao': observacao, 'confirmado': confirmado}),
    )) as Map<String, dynamic>;
    return ResultadoMedicao(
      registrado: corpo['registrado'] != false,
      foraDaFaixa: corpo['fora_da_faixa'] == true || corpo['alerta_fora'] == true,
    );
  }

  // POST /api/checkin/<id>/nao-realizado: motivo é a chave aceita pelo backend (ex.: 'dormindo')
  static Future<void> registrarNaoRealizado(String itemId, String motivo, String observacao) async {
    _tratar(await http.post(
      _url('${_item(itemId)}/nao-realizado'),
      headers: _json,
      body: jsonEncode({'motivo': motivo, 'observacao': observacao}),
    ));
  }

  // POST /api/turno/encerrar: fecha o turno no banco com a passagem; o backend limpa a sessão
  static Future<void> encerrarTurno(String passagem) async {
    _tratar(await http.post(
      _url('/api/turno/encerrar'),
      headers: _json,
      body: jsonEncode({'passagem': passagem}),
    ));
  }

  // POST /api/sair: limpa a sessão no backend sem encerrar o turno
  static Future<void> sair() async {
    _tratar(await http.post(_url('/api/sair'), headers: _json, body: '{}'));
  }
}
