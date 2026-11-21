import 'package:flutter/material.dart';

// Card de perfil da tela inicial (index): avatar com as iniciais, título e descrição
class PerfilTile extends StatelessWidget {
  final String iniciais;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap; // função chamada quando o card é tocado
  final bool destaque; // true no card do Gestor: avatar preenchido em verde-água

  const PerfilTile({ //construtor da classe PerfilTile
    super.key,
    required this.iniciais,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias, // o efeito do toque respeita o canto arredondado
      child: ListTile(
        leading: CircleAvatar(
          radius: 24, // 48px de diâmetro
          backgroundColor: destaque ? cores.primary : cores.primaryContainer,
          foregroundColor: destaque ? cores.onPrimary : cores.onPrimaryContainer,
          child: Text(
            iniciais,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.chevron_right_rounded),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        horizontalTitleGap: 12,
        onTap: onTap,
      ),
    );
  }
}