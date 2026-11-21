import 'package:flutter/material.dart';

import '../models/estado_caneleira.dart';

// Card da caneleira: status da conexão, bateria, sinal e se está presa à perna
class CaneleiraCard extends StatelessWidget {
  final EstadoCaneleira estado;
  final bool conectado; // o app está conectado ao broker

  const CaneleiraCard({
    super.key,
    required this.estado,
    required this.conectado,
  });

  // Monta a linha de detalhes conforme a situação da conexão
  String _montarDetalhes() {
    if (!conectado) return 'App sem conexão com o servidor';
    if (!estado.online) return 'Desligada ou fora da rede';
    final partes = <String>[estado.sinal];
    if (estado.bateria != null) partes.insert(0, 'Bateria ${estado.bateria}%');
    if (estado.emUso == true) partes.add('Na perna');
    if (estado.emUso == false) partes.add('Fora da perna');
    return partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final online = conectado && estado.online;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: cores.primaryContainer,
              foregroundColor: cores.onPrimaryContainer,
              child: const Icon(Icons.sensors_rounded, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Caneleira 01',
                    style: textos.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _montarDetalhes(),
                    style: textos.bodySmall?.copyWith(
                      color: cores.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Chip(
              label: Text(online ? 'Conectada' : 'Desconectada'),
              labelStyle: textos.labelMedium?.copyWith(
                color: online ? cores.onPrimaryContainer : cores.error,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: online
                  ? cores.primaryContainer
                  : cores.errorContainer,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}