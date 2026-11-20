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

  // POST /api/sair: limpa a sessão no backend sem encerrar o turno
  static Future<void> sair() async {
    _tratar(await http.post(_url('/api/sair'), headers: _json, body: '{}'));
  }
}
