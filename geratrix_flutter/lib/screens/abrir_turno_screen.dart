import 'package:flutter/material.dart';

import '../models/cuidador.dart';

// Tela de Abertura de Turno: exibe o resumo do plantão anterior, alertas e pendências
class AbrirTurnoScreen extends StatelessWidget {
  const AbrirTurnoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Recebe o cuidador autenticado da tela de PIN
    final cuidador = ModalRoute.of(context)!.settings.arguments as Cuidador;
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            Text(
              'Abertura de turno',
              style: textos.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 28,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),

            // Identificação do Cuidador
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: cores.primaryContainer,
                  foregroundColor: cores.onPrimaryContainer,
                  child: Text(
                    cuidador.iniciais,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cuidador.nome,
                        style: textos.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Iniciando plantão',
                        style: textos.labelMedium?.copyWith(color: cores.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Text(
              'PLANTÃO ANTERIOR',
              style: textos.labelMedium?.copyWith(
                color: cores.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),

            // Informação do último turno (AppCard Padrão)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history_rounded, size: 20, color: cores.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(
                          'Encerrado às 07:15',
                          style: textos.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Por Enzo Senatori',
                      style: textos.bodyMedium?.copyWith(color: cores.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Banner de Alerta Crítico (Sem sombra, fundo errorContainer)
            Card(
              color: cores.errorContainer,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_rounded, color: cores.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '2 medições fora da faixa',
                            style: textos.titleSmall?.copyWith(color: cores.error, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pressão arterial da Dona Carmem e glicemia do Sr. João.',
                            style: textos.bodyMedium?.copyWith(color: cores.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Banner de Pendências/Passagem de plantão (Sem sombra, fundo surfaceVariant)
            Card(
              color: cores.surfaceContainerHighest,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: cores.onSurfaceVariant, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Passagem de plantão',
                            style: textos.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dona Carmem reclamou de dores na lombar durante a madrugada. Observar ao longo do dia.',
                            style: textos.bodyMedium?.copyWith(color: cores.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),

            // Botão de Iniciar
            FilledButton(
              onPressed: () {
                // Provisório: Aviso até a tela de Lista existir
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lista de tarefas em construção')),
                );
              },
              child: const Text('Iniciar plantão'),
            ),
          ],
        ),
      ),
    );
  }
}