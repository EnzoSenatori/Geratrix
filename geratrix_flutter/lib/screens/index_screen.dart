import 'package:flutter/material.dart';

import '../dados/dados_exemplo.dart';
import '../routes.dart';

// Tela inicial (Index): seleção do perfil do cuidador ou acesso ao gestor
class IndexScreen extends StatelessWidget {
  const IndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Filtra apenas os cuidadores ativos conforme regra do backend (WHERE ativo = 1)
    final cuidadoresAtivos = cuidadores.where((c) => c.ativo).toList();

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

              // Grade de seleção de cuidadores ativos
              Expanded(
                child: GridView.builder(
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}