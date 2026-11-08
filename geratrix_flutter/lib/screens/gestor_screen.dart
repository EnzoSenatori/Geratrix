import 'package:flutter/material.dart';

import '../models/cuidador.dart';
import '../routes.dart';

// Lista de cuidadores (incluindo uma inativa para exemplo visual)
const _cuidadores = [
  Cuidador(nome: 'Theo Casella Mendonça', iniciais: 'TCM', turnoPadrao: 'Manhã', pin: '1234', ativo: true),
  Cuidador(nome: 'Enzo Senatori', iniciais: 'ES', turnoPadrao: 'Tarde', pin: '1234', ativo: true),
  Cuidador(nome: 'Rafael de Oliveira Corrêa', iniciais: 'RC', turnoPadrao: 'Noite', pin: '1234', ativo: true),
  Cuidador(nome: 'Maria da Silva', iniciais: 'MS', turnoPadrao: 'Folga', pin: '0000', ativo: false),
];

// Painel do Gestor: visualização do status da equipe e acesso a relatórios
class GestorScreen extends StatelessWidget {
  const GestorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Text(
                'Painel da Direção',
                style: textos.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            // Botão para navegar até o histórico de turnos e relatórios gerenciais
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.historicoTurnos);
                },
                icon: const Icon(Icons.assessment_outlined),
                label: const Text('Ver histórico de turnos e relatórios'),
              ),
            ),
            const SizedBox(height: 16),
            // Expanded faz a lista ocupar todo o espaço restante da tela
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                itemCount: _cuidadores.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final cuidador = _cuidadores[index];
                  
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: cores.primaryContainer,
                        foregroundColor: cores.onPrimaryContainer,
                        child: Text(
                          cuidador.iniciais,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        cuidador.nome,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Turno ${cuidador.turnoPadrao}'),
                      trailing: Chip(
                        label: Text(cuidador.ativo ? 'Ativo' : 'Inativo'),
                        labelStyle: TextStyle(
                          color: cuidador.ativo ? cores.onPrimaryContainer : cores.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        backgroundColor: cuidador.ativo ? cores.primaryContainer : cores.errorContainer,
                        side: BorderSide.none,
                        shape: const StadiumBorder(), // Formato de pílula
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}