import 'package:flutter/material.dart';

import '../models/turno_historico.dart';

// Dados fictícios de histórico de turnos anteriores
final _historicoMock = [
  TurnoHistorico(
    data: 'Hoje, 07:00',
    cuidador: 'Rafael de Oliveira Corrêa',
    turno: 'Noite',
    concluidas: 2,
    naoRealizadas: 1,
    observacoes: 'Dona Maria acordou duas vezes durante a noite. Sr. José recusou o lanche das 22h.',
  ),
  TurnoHistorico(
    data: 'Ontem, 19:00',
    cuidador: 'Enzo Senatori',
    turno: 'Tarde',
    concluidas: 6,
    naoRealizadas: 0,
    observacoes: 'Turno sem intercorrências graves. Todos os medicamentos administrados.',
  ),
];

// Tela de Histórico de Turnos e Relatórios Gerenciais
class HistoricoTurnosScreen extends StatelessWidget {
  const HistoricoTurnosScreen({super.key});

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
        title: const Text('Histórico de Turnos'),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: _historicoMock.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final turno = _historicoMock[index];

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          turno.data,
                          style: textos.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Chip(
                          label: Text(turno.turno),
                          labelStyle: TextStyle(
                            color: cores.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          backgroundColor: cores.primaryContainer,
                          side: BorderSide.none,
                          shape: const StadiumBorder(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cuidador: ${turno.cuidador}',
                      style: textos.bodyMedium?.copyWith(
                        color: cores.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Ajustado para cores.secondary para garantir contraste em textos/ícones sobre fundo claro
                        Text(
                          '${turno.concluidas} concluídas',
                          style: textos.bodySmall?.copyWith(
                            color: cores.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${turno.naoRealizadas} não realizadas',
                          style: textos.bodySmall?.copyWith(
                            color: cores.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (turno.observacoes.isNotEmpty) ...[
                      const Divider(height: 24),
                      Text(
                        'Passagem de plantão:',
                        style: textos.labelMedium?.copyWith(
                          color: cores.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        turno.observacoes,
                        style: textos.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}