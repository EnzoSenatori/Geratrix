import 'package:flutter/material.dart';

// Card de perfil da tela inicial (index): avatar com as iniciais, título e a descrição do turno
class PerfilTile extends StatelessWidget {
  final String iniciais;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap; // função que será chamada quando o card for clicado

  const PerfilTile({
    super.key,
    required this.iniciais,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        radius: 22, // 44px de diâmetro
        backgroundColor: tema.colorScheme.primary,
        foregroundColor: tema.colorScheme.onPrimary,
        child: Text(
          iniciais,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        titulo,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitulo),
      shape: RoundedRectangleBorder( // borda e canto do .card
        side: BorderSide(color: tema.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      horizontalTitleGap: 12, // espaço entre o avatar e texto; o gap do .card
      onTap: onTap,
    );
  }
}