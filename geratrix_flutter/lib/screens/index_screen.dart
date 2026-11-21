import 'package:flutter/material.dart';

import '../models/cuidador.dart';
import '../routes.dart';
import '../services/api.dart';

// Tela inicial (Index): seleção do perfil do cuidador ou acesso ao gestor
class IndexScreen extends StatefulWidget {
  const IndexScreen({super.key});

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  List<Cuidador>? _cuidadores;
  bool _falhou = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  // Busca os cuidadores ativos no backend (o filtro ativo = 1 é feito pela API)
  Future<void> _carregar() async {
    setState(() {
      _cuidadores = null;
      _falhou = false;
    });
    try {
      final lista = await Api.listarCuidadores();
      if (mounted) setState(() => _cuidadores = lista);
    } catch (_) {
      if (mounted) setState(() => _falhou = true);
    }
  }

  // Mostra carregando, erro com "Tentar de novo" ou a grade de perfis
  Widget _montarConteudo(ColorScheme cores, TextTheme textos) {
    if (_falhou) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Não foi possível carregar os perfis.',
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
    }

    final cuidadoresAtivos = _cuidadores;
    if (cuidadoresAtivos == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: cuidadoresAtivos.length,
      itemBuilder: (context, index) {
        final cuidador = cuidadoresAtivos[index];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              // Navega para a tela de PIN passando o cuidador selecionado
              Navigator.pushNamed(
                context,
                AppRoutes.pin,
                arguments: cuidador,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: cores.primaryContainer,
                    foregroundColor: cores.onPrimaryContainer,
                    child: Text(
                      cuidador.iniciais,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    cuidador.nome,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textos.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Turno ${cuidador.turnoPadrao}',
                    style: textos.bodySmall?.copyWith(
                      color: cores.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Cabeçalho com o botão de acesso à tela do Gestor
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.gestor);
                  },
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Entrar como gestor'),
                ),
              ),
              const SizedBox(height: 32),

              // Identificação do aplicativo
              Text(
                'Geratrix',
                textAlign: TextAlign.center,
                style: textos.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cores.primary,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Quem está assumindo o plantão?',
                textAlign: TextAlign.center,
                style: textos.titleMedium?.copyWith(
                  color: cores.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // Grade de seleção de cuidadores ativos (vinda da API)
              Expanded(child: _montarConteudo(cores, textos)),
            ],
          ),
        ),
      ),
    );
  }
}
