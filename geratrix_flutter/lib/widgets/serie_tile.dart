import 'package:flutter/material.dart';

import '../models/serie_exercicio.dart';

// Linha da tabela de séries: número, repetições válidas, status e ADM média
class SerieTile extends StatelessWidget {
  final SerieExercicio serie;

  const SerieTile({super.key, required this.serie});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final destaque = textos.titleMedium?.copyWith(fontWeight: FontWeight.w700);

    return ListTile(
      leading: SizedBox(
        width: 24,
        child: Text(
          '${serie.numero}',
          style: destaque?.copyWith(color: cores.onSurfaceVariant),
        ),
      ),
      minLeadingWidth: 24,
      title: Text('${serie.validas}/${serie.total} válidas', style: destaque),
      subtitle: Text(serie.status),
      trailing: Text('${serie.admMedia.toStringAsFixed(0)}°', style: destaque),
    );
  }
}