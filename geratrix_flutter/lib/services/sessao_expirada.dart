import 'package:flutter/material.dart';

import '../routes.dart';

// Chamada quando a API responde 401: limpa a pilha de telas, volta para os perfis e avisa o cuidador
void voltarParaPerfis(BuildContext context) {
  final mensageiro = ScaffoldMessenger.of(context);
  Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.index, (rota) => false);
  mensageiro.showSnackBar(
    const SnackBar(content: Text('Sessão expirada. Entre novamente.')),
  );
}
