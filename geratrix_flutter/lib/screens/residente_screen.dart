import 'package:flutter/material.dart';

import '../models/residente.dart';
import 'erro_screen.dart';

// Tela de Prontuário Rápido do Residente
class ResidenteScreen extends StatelessWidget {
  const ResidenteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final residente = ModalRoute.of(context)?.settings.arguments as Residente?;

    // Proteção contra navegação direta / F5 sem argumento
    if (residente == null) {
      return const ErroScreen(
        mensagem: 'Esta tela abre a partir do início do app.',
      );
    }

    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Prontuário Rápido'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Identificação do Residente
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: cores.primaryContainer,
                  foregroundColor: cores.onPrimaryContainer,
                  child: Text(
                    residente.iniciais,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        residente.nome,
                        style: textos.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        residente.quarto,
                        style: textos.bodyLarge?.copyWith(
                          color: cores.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Alergias
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: cores.secondary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Alergias',
                          style: textos.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (residente.alergias.isEmpty)
                      Text('Nenhuma alergia conhecida.', style: textos.bodyMedium)
                    else
                      Wrap(
                        spacing: 8,
                        children: residente.alergias.map((alergia) {
                          return Chip(
                            label: Text(alergia),
                            backgroundColor: cores.errorContainer,
                            labelStyle: TextStyle(
                              color: cores.error,
                              fontWeight: FontWeight.bold,
                            ),
                            side: BorderSide.none,
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Restrições Alimentares
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.restaurant_rounded, color: cores.secondary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Restrições Alimentares',
                          style: textos.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (residente.restricoesAlimentares.isEmpty)
                      Text('Sem restrições cadastradas.', style: textos.bodyMedium)
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: residente.restricoesAlimentares.map((restricao) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text('• $restricao', style: textos.bodyMedium),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Contato de Emergência
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.phone_rounded, color: cores.secondary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Contato de Emergência',
                          style: textos.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      residente.contatoEmergencia,
                      style: textos.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Observações Médicas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.medical_information_outlined, color: cores.secondary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Observações Médicas',
                          style: textos.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      residente.observacoesMedicas,
                      style: textos.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}