import 'package:flutter/material.dart';

// Modelo temporário para o histórico de plantões finalizados
class TurnoHistorico {
  final String id;
  final String data;
  final String cuidador;
  final String turno;
  final int concluidas;
  final int naoRealizadas;
  final String passagemPlantao;

  const TurnoHistorico({
    required this.id,
    required this.data,
    required this.cuidador,
    required this.turno,
    required this.concluidas,
    required this.naoRealizadas,
    required this.passagemPlantao,
  });
}

const _historicoMock = [
  TurnoHistorico(
    id: '101',
    data: 'Hoje, 07:15',
    cuidador: 'Enzo Senatori',
    turno: 'Noite',
    concluidas: 12,
    naoRealizadas: 1,
    passagemPlantao: 'Dona Carmem reclamou de dor lombar. Medicação administrada conforme prescrição.',
  ),
  TurnoHistorico(
    id: '100',
    data: 'Ontem, 19:00',
    cuidador: 'Theo Casella Mendonça',
    turno: 'Tarde',
    concluidas: 15,
    naoRealizadas: 0,
    passagemPlantao: 'Sem intercorrências graves. Todos os residentes alimentados.',
  ),
];

// Tela de consulta do histórico de turnos encerrados para a gestão
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
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final turno = _historicoMock[index];

            return Card(
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: cores.primaryContainer,
                  foregroundColor: cores.onPrimaryContainer,
                  child: const Icon(Icons.history_rounded, size: 20),
                ),
                title: Text(
                  '${turno.cuidador} (${turno.turno})',
                  style: textos.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(turno.data),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Concluídas: ${turno.concluidas}', style: TextStyle(color: cores.primary, fontWeight: FontWeight.bold)),
                      Text('Não realizadas: ${turno.naoRealizadas}', style: TextStyle(color: cores.error, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Passagem de plantão:',
                    style: textos.labelMedium?.copyWith(color: cores.onSurfaceVariant, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    turno.passagemPlantao,
                    style: textos.bodyMedium,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}