import 'package:flutter/material.dart';

import '../models/item_rotina.dart';
import '../routes.dart';

// Dados provisórios
const _itensMock = [
  ItemRotina('1', '08:00', 'Medicação', 'Dona Carmem', 'feito'),
  ItemRotina('2', '09:40', 'Pressão Arterial', 'Sr. João', 'atrasado'),
  ItemRotina('3', '10:30', 'Lanche da Manhã', 'Todos', 'pendente'),
  ItemRotina('4', '11:00', 'Banho', 'Dona Carmem', 'pendente'),
];

// Tela central do plantão: lista de tarefas do agora
class ListaScreen extends StatefulWidget {
  const ListaScreen({super.key});

  @override
  State<ListaScreen> createState() => _ListaScreenState();
}

class _ListaScreenState extends State<ListaScreen> {
  String _filtroAtual = 'Todos';

  Widget _buildFiltro(String rotulo, ColorScheme cores) {
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

    // Lógica do app.py: cálculo de progresso e filtragem
    final total = _itensMock.length;
    final feitos = _itensMock.where((i) => i.status == 'feito').length;
    final progresso = total > 0 ? feitos / total : 0.0;

    final itensFiltrados = _itensMock.where((item) {
      if (_filtroAtual == 'Todos') return true;
      if (_filtroAtual == 'Feitos') return item.status == 'feito';
      return item.status != 'feito'; 
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
                _buildFiltro('Todos', cores),
                const SizedBox(width: 8),
                _buildFiltro('A Fazer', cores),
                const SizedBox(width: 8),
                _buildFiltro('Feitos', cores),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lista de Cards
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96), 
              itemCount: itensFiltrados.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = itensFiltrados[index];
                final isAtrasado = item.status == 'atrasado';
                final isFeito = item.status == 'feito';

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
                        isFeito ? Icons.check_rounded : (isAtrasado ? Icons.warning_rounded : Icons.schedule_rounded),
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
                    subtitle: Text('${item.horario} • ${item.residente}'),
                    trailing: isFeito ? null : const Icon(Icons.chevron_right_rounded),
                    onTap: isFeito ? null : () {
                      // NOVO: Navega para a rota de check-in enviando a tarefa na bagagem!
                      Navigator.pushNamed(context, AppRoutes.checkin, arguments: item);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // FAB para ações rápidas (ex: encerrar turno)
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