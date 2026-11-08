import 'package:flutter/material.dart';

import '../models/residente.dart';

// Tela de prontuário rápido do residente (exibe alergias, quarto e emergência)
class ResidenteScreen extends StatelessWidget {
  const ResidenteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Recebe o objeto Residente passado via arguments (ou usa um mock de fallback se nulo)
    final args = ModalRoute.of(context)?.settings.arguments;
    final residente = (args is Residente)
        ? args
        : const Residente(
            id: '1',
            nome: 'Dona Carmem Silva',
            quarto: 'Quarto 102 - Leito A',
            iniciais: 'CS',
            alergias: ['Dipirona', 'Frutos do Mar'],
            restricoesAlimentares: ['Dieta hipossódica (pouco sal)', 'Sem lactose'],
            contatoEmergencia: 'Filha: Ana Maria (11) 98765-4321',
            observacoesMedicas: 'Hipertensa. Apresenta leve tontura ao se levantar rapidamente.',
          );

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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            // Cabeçalho de Identificação do Residente
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: cores.primaryContainer,
                  foregroundColor: cores.onPrimaryContainer,
                  child: Text(
                    residente.iniciais,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        residente.quarto,
                        style: textos.bodyMedium?.copyWith(color: cores.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Card de Alergias (Alerta com fundo errorContainer se houver alergias)
            Card(
              color: residente.alergias.isNotEmpty ? cores.errorContainer : cores.surface,
              elevation: residente.alergias.isNotEmpty ? 0 : 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: residente.alergias.isNotEmpty ? cores.error : cores.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ALERGIAS CONHECIDAS',
                          style: textos.labelMedium?.copyWith(
                            color: residente.alergias.isNotEmpty ? cores.error : cores.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      residente.alergias.isNotEmpty
                          ? residente.alergias.join(', ')
                          : 'Nenhuma alergia registrada.',
                      style: textos.bodyLarge?.copyWith(
                        color: residente.alergias.isNotEmpty ? cores.error : cores.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card de Restrições Alimentares
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.restaurant_rounded, color: cores.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'RESTRIÇÕES ALIMENTARES',
                          style: textos.labelMedium?.copyWith(
                            color: cores.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final restricao in residente.restricoesAlimentares) ...[
                      Row(
                        children: [
                          Icon(Icons.circle, size: 6, color: cores.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              restricao,
                              style: textos.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card de Observações Médicas e Contato de Emergência
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.medical_information_rounded, color: cores.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'OBSERVAÇÕES CLÍNICAS',
                          style: textos.labelMedium?.copyWith(
                            color: cores.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      residente.observacoesMedicas,
                      style: textos.bodyMedium,
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Icon(Icons.phone_rounded, color: cores.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'CONTATO DE EMERGÊNCIA',
                          style: textos.labelMedium?.copyWith(
                            color: cores.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      residente.contatoEmergencia,
                      style: textos.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
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