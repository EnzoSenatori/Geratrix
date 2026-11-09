import 'package:flutter/material.dart';

import '../models/cuidador.dart';
import '../routes.dart';
import 'erro_screen.dart';

// Tela de verificação de PIN de acesso do cuidador
class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';

  void _onTeclaPressionada(String valor) {
    if (_pin.length < 4) {
      setState(() {
        _pin += valor;
      });
      if (_pin.length == 4) {
        _validarPin();
      }
    }
  }

  void _onApagar() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _validarPin() {
    final cuidador = ModalRoute.of(context)?.settings.arguments as Cuidador?;
    // Aceita o PIN configurado no cuidador ou a senha genérica "1234"
    if (_pin == '1234' || (cuidador != null && _pin == cuidador.pin)) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.abrirTurno,
        arguments: cuidador,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN incorreto. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _pin = '';
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
      onTap: () => _onTeclaPressionada(rotulo),
      borderRadius: BorderRadius.circular(40),
      child: Center(
        child: Text(
          rotulo,
          style: textos.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: cores.onSurface,
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
                    onPressed: _onApagar,
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