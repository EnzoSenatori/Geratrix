import 'package:flutter/material.dart';

import '../models/cuidador.dart';
import '../routes.dart';
import '../services/api.dart';
import 'erro_screen.dart';

// Tela de verificação de PIN de acesso do cuidador
class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  bool _enviando = false; // trava o teclado enquanto o backend confere o PIN
  bool _bloqueado = false; // 429: teclado fica travado até o cuidador voltar
  String? _erro; // mensagem do backend (mesmo texto da tela HTML)

  // Teclado só responde quando não está enviando nem bloqueado
  bool get _tecladoAtivo => !_enviando && !_bloqueado;

  // Acrescenta um dígito; com 4 dígitos envia para o backend
  void _onTeclaPressionada(String valor) {
    if (!_tecladoAtivo) return;
    if (_pin.length < 4) {
      setState(() {
        _pin += valor;
      });
      if (_pin.length == 4) {
        _validarPin();
      }
    }
  }

  // Apaga o último dígito
  void _onApagar() {
    if (!_tecladoAtivo) return;
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  // Envia o PIN para o backend (hash + limite de tentativas) e segue para a lista ou para a abertura do turno
  Future<void> _validarPin() async {
    final cuidador = ModalRoute.of(context)?.settings.arguments as Cuidador?;
    if (cuidador == null) return;

    setState(() {
      _enviando = true;
      _erro = null;
    });

    try {
      final resultado = await Api.entrar(cuidador.id, _pin);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        resultado.turnoAberto ? AppRoutes.lista : AppRoutes.abrirTurno,
      );
    } on ErroApi catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = erro.mensagem;
        _bloqueado = erro.bloqueado;
        _pin = '';
        _enviando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível falar com o servidor. Tente novamente.';
        _pin = '';
        _enviando = false;
      });
    }
  }

  Widget _montarBolinha(int index, ColorScheme cores) {
    final preenchido = index < _pin.length;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: preenchido ? cores.primary : cores.surfaceContainerHighest,
      ),
    );
  }

  Widget _montarTecla(String rotulo, ColorScheme cores, TextTheme textos) {
    return InkWell(
      onTap: _tecladoAtivo ? () => _onTeclaPressionada(rotulo) : null,
      borderRadius: BorderRadius.circular(40),
      child: Center(
        child: Text(
          rotulo,
          style: textos.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: _tecladoAtivo ? cores.onSurface : cores.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cuidador = ModalRoute.of(context)?.settings.arguments as Cuidador?;

    // Proteção contra F5 / acesso direto sem seleção de cuidador
    if (cuidador == null) {
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              'Digite seu PIN',
              style: textos.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Identificação: ${cuidador.nome}',
              style: textos.bodyLarge?.copyWith(color: cores.onSurfaceVariant),
            ),
            const SizedBox(height: 32),

            // Indicadores do PIN (4 bolinhas)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _montarBolinha(0, cores),
                const SizedBox(width: 16),
                _montarBolinha(1, cores),
                const SizedBox(width: 16),
                _montarBolinha(2, cores),
                const SizedBox(width: 16),
                _montarBolinha(3, cores),
              ],
            ),
            const SizedBox(height: 24),

            // Mensagem do backend: PIN incorreto, tentativas restantes ou bloqueio
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  _erro!,
                  textAlign: TextAlign.center,
                  style: textos.bodyLarge?.copyWith(
                    color: cores.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (_enviando) const CircularProgressIndicator(),
            const Spacer(),

            // Teclado numérico
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  for (var i = 1; i <= 9; i++)
                    _montarTecla(i.toString(), cores, textos),
                  const SizedBox.shrink(),
                  _montarTecla('0', cores, textos),
                  IconButton(
                    onPressed: _tecladoAtivo ? _onApagar : null,
                    icon: const Icon(Icons.backspace_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}