import 'package:flutter/material.dart';

import 'api.dart';
import 'sessao_expirada.dart';

// Envia um registro à API e trata os casos comuns das telas de check-in.
// Devolve true quando a tela deve fechar e a lista recarregar: gravado, ou 409 (já registrado hoje).
Future<bool> enviarRegistro(
  BuildContext context,
  Future<void> Function() envio,
  String mensagemSucesso,
) async {
  final mensageiro = ScaffoldMessenger.of(context);
  try {
    await envio();
    mensageiro.showSnackBar(SnackBar(content: Text(mensagemSucesso)));
    return true;
  } on SessaoExpirada {
    if (context.mounted) voltarParaPerfis(context);
    return false;
  } on ErroApi catch (erro) {
    mensageiro.showSnackBar(SnackBar(content: Text(erro.mensagem)));
    return erro.jaRegistrado;
  } catch (_) {
    mensageiro.showSnackBar(
      const SnackBar(content: Text('Não foi possível falar com o servidor. Tente novamente.')),
    );
    return false;
  }
}
