import 'package:flutter/material.dart';

import '../routes.dart';

// Tela de erro amigável (404 / Falhas de navegação)
class ErroScreen extends StatelessWidget {
  final String? mensagem;

  const ErroScreen({super.key, this.mensagem});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ops! Algo deu errado'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ícone de alerta em destaque
              CircleAvatar(
                radius: 40,
                backgroundColor: cores.errorContainer,
                foregroundColor: cores.error,
                child: const Icon(Icons.error_outline_rounded, size: 48),
              ),
              const SizedBox(height: 24),

              Text(
                'Página não encontrada',
                textAlign: TextAlign.center,
                style: textos.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                mensagem ?? 'A tela que você tentou acessar não existe ou foi movida.',
                textAlign: TextAlign.center,
                style: textos.bodyLarge?.copyWith(
                  color: cores.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Botão para voltar em segurança à tela inicial
              FilledButton.icon(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.index,
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home_rounded),
                label: const Text('Voltar para o início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}