import 'package:flutter/material.dart';

import '../models/item_rotina.dart';
import '../routes.dart';
import '../services/api.dart';
import '../services/sessao_expirada.dart';

// Tela central do plantão: lista de tarefas do agora
class ListaScreen extends StatefulWidget {
  const ListaScreen({super.key});

  @override
  State<ListaScreen> createState() => _ListaScreenState();
}

class _ListaScreenState extends State<ListaScreen> {
  String _filtroAtual = 'Todos';

  // Itens do turno vindos do backend; recarregados depois de cada registro
  List<ItemRotina> _itens = [];
  bool _carregando = true;
  bool _falhou = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  // Busca os itens do turno na API; sem sessão (401), volta para os perfis
  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _falhou = false;
    });
    try {
      final itens = await Api.itensDoTurno();
      if (mounted) {
        setState(() {
          _itens = itens;
          _carregando = false;
        });
      }
    } on SessaoExpirada {
      if (mounted) voltarParaPerfis(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _falhou = true;
        });
      }
    }
  }

  // Sai da sessão no backend (sem encerrar o turno) e volta para os perfis
  Future<void> _sair() async {
    try {
      await Api.sair();
    } catch (_) {
      // Mesmo sem resposta do servidor, o app volta para os perfis
    }
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.index, (route) => false);
  }

  // Abre a tela de registro adequada; se ela gravou algo (ou o item já estava registrado), recarrega a lista da API
  Future<void> _abrirRegistro(ItemRotina item) async {
    String rota = AppRoutes.checkin;
    if (item.natureza == 'medicao') rota = AppRoutes.checkinSinaisVitais;
    if (item.natureza == 'medicacao') rota = AppRoutes.checkinMedicamento;
    if (item.natureza == 'exercicio') rota = AppRoutes.exercicio;

    final resultado = await Navigator.pushNamed(context, rota, arguments: item);
    if (!mounted || resultado != true) return;
    await _carregar();
  }

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

    final total = _itens.length;
    final feitos = _itens.where((i) => i.registrado).length;
    final progresso = total > 0 ? feitos / total : 0.0;

    final itensFiltrados = _itens.where((item) {
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
            onPressed: _sair,
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _falhou
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Não foi possível carregar a lista.',
                        style: textos.bodyLarge?.copyWith(color: cores.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _carregar,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tentar de novo'),
                      ),
                    ],
                  ),
                )
              : _montarLista(cores, textos, itensFiltrados, progresso),
      floatingActionButton: _carregando || _falhou
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.encerrarTurno, arguments: _itens);
              },
              icon: const Icon(Icons.stop_rounded),
              label: const Text('Encerrar turno'),
            ),
    );
  }

  // Barra de progresso, filtros e cartões dos itens
  Widget _montarLista(ColorScheme cores, TextTheme textos, List<ItemRotina> itensFiltrados, double progresso) {
    return Column(
        children: [
          LinearProgressIndicator(
            value: progresso,
            backgroundColor: cores.surfaceContainerHighest,
            color: cores.primary,
            minHeight: 8,
          ),
          const SizedBox(height: 16),
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
                final isFeito = item.status == 'feito';
                final isNaoRealizado = item.status == 'nao_realizado';
                final isRegistrado = item.registrado;

                // Define as cores e ícones conforme o status do item
                Color corFundoAvatar = cores.surfaceContainerHighest;
                Color corIconeAvatar = cores.onSurfaceVariant;
                IconData iconeAvatar = Icons.schedule_rounded;

                if (isFeito) {
                  corFundoAvatar = cores.primaryContainer;
                  corIconeAvatar = cores.onPrimaryContainer;
                  iconeAvatar = Icons.check_rounded;
                } else if (isNaoRealizado) {
                  corFundoAvatar = cores.errorContainer;
                  corIconeAvatar = cores.error;
                  iconeAvatar = Icons.close_rounded;
                } else if (isAtrasado) {
                  corFundoAvatar = cores.errorContainer;
                  corIconeAvatar = cores.error;
                  iconeAvatar = Icons.warning_rounded;
                }

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: corFundoAvatar,
                      foregroundColor: corIconeAvatar,
                      child: Icon(iconeAvatar, size: 20),
                    ),
                    title: Text(
                      item.tipo,
                      style: textos.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: isRegistrado ? TextDecoration.lineThrough : null,
                        color: isRegistrado ? cores.onSurfaceVariant : cores.onSurface,
                      ),
                    ),
                    subtitle: Text('${item.horario} • ${item.residente.nome}'),
                    trailing: isRegistrado ? null : const Icon(Icons.chevron_right_rounded),
                    onTap: isRegistrado ? null : () => _abrirRegistro(item),
                  ),
                );
              },
            ),
          ),
        ],
    );
  }
}