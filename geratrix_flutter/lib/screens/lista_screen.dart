import 'package:flutter/material.dart';

import '../dados/dados_exemplo.dart';
import '../routes.dart';

// Tela central do plantão: lista de tarefas do agora
class ListaScreen extends StatefulWidget {
  const ListaScreen({super.key});

  @override
  State<ListaScreen> createState() => _ListaScreenState();
}

class _ListaScreenState extends State<ListaScreen> {
  String _filtroAtual = 'Todos';

  Widget _montarFiltro(String rotulo, ColorScheme cores) {
    final isSelecionado = _filtroAtual == rotulo;
    return FilterChip(
      label: Text(rotulo),
      selected: isSelecionado,
      onSelected: (bool selecionado) {
        setState(() => _filtroAtual = rotulo);
      },
      backgroundColor: cores.surfaceContainerHighest,
      selectedColor: cores.primaryContainer,
      labelStyle: TextStyle(
        color: isSelecionado ? cores.onPrimaryContainer : cores.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      shape: const StadiumBorder(),
      side: BorderSide.none,
      showCheckmark: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    final total = itensDoDia.length;
    final feitos = itensDoDia.where((i) => i.registrado).length;
    final progresso = total > 0 ? feitos / total : 0.0;

    final itensFiltrados = itensDoDia.where((item) {
      if (_filtroAtual == 'Todos') return true;
      if (_filtroAtual == 'Feitos') return item.registrado;
      return !item.registrado; // "A Fazer"
    }).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Lista do agora',
          style: textos.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              // Rota de sair: volta para a Index
              Navigator.pushReplacementNamed(context, AppRoutes.index);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de progresso linear
          LinearProgressIndicator(
            value: progresso,
            backgroundColor: cores.surfaceContainerHighest,
            color: cores.primary,
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          
          // Trilha de filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _montarFiltro('Todos', cores),
                const SizedBox(width: 8),
                _montarFiltro('A Fazer', cores),
                const SizedBox(width: 8),
                _montarFiltro('Feitos', cores),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              itemCount: itensFiltrados.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = itensFiltrados[index];
                final isAtrasado = item.status == 'atrasado';
                final isFeito = item.registrado;

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isFeito
                          ? cores.primaryContainer
                          : (isAtrasado ? cores.errorContainer : cores.surfaceContainerHighest),
                      foregroundColor: isFeito
                          ? cores.onPrimaryContainer
                          : (isAtrasado ? cores.error : cores.onSurfaceVariant),
                      child: Icon(
                        isFeito
                            ? Icons.check_rounded
                            : (isAtrasado ? Icons.warning_rounded : Icons.schedule_rounded),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.tipo,
                      style: textos.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: isFeito ? TextDecoration.lineThrough : null,
                        color: isFeito ? cores.onSurfaceVariant : cores.onSurface,
                      ),
                    ),
                    subtitle: Text('${item.horario} • ${item.residente.nome}'),
                    trailing: isFeito ? null : const Icon(Icons.chevron_right_rounded),
                    onTap: isFeito
                        ? null
                        : () {
                            if (item.tipo.contains('Medição') || item.tipo.contains('Pressão')) {
                              Navigator.pushNamed(context, AppRoutes.checkinSinaisVitais, arguments: item);
                            } else if (item.tipo.contains('Medicação') || item.tipo.contains('Remédio')) {
                              Navigator.pushNamed(context, AppRoutes.checkinMedicamento, arguments: item);
                            } else {
                              Navigator.pushNamed(context, AppRoutes.checkin, arguments: item);
                            }
                          },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tela Encerrar Turno em construção')),
          );
        },
        child: const Icon(Icons.stop_rounded),
      ),
    );
  }
}