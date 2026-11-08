import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/cuidador.dart';

// Tela de inserção do código PIN para login
class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pinAtual = '';
  String? _erro;

  // Adiciona um dígito ao PIN
  void _digitar(String digito) {
    if (_pinAtual.length < 4) {
      setState(() {
        _pinAtual += digito;
        _erro = null;
      });
      HapticFeedback.lightImpact();
    }
  }

  // Apaga o último dígito
  void _apagar() {
    if (_pinAtual.isNotEmpty) {
      setState(() {
        _pinAtual = _pinAtual.substring(0, _pinAtual.length - 1);
        _erro = null;
      });
      HapticFeedback.lightImpact();
    }
  }

  // Valida o PIN e prossegue
  void _entrar(Cuidador cuidador) {
    if (_pinAtual == cuidador.pin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bem-vindo! Abertura de turno em construção.')),
      );
    } else {
      setState(() {
        _erro = 'PIN incorreto. Tente novamente.';
        _pinAtual = '';
      });
      HapticFeedback.heavyImpact();
    }
  }

  // Bolinha indicadora do PIN
  Widget _buildBolinha(bool preenchida, ColorScheme cores) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: preenchida ? cores.primary : null,
        border: preenchida ? null : Border.all(color: cores.outline, width: 2),
      ),
    );
  }

  // Tecla do teclado numérico
  Widget _buildTecla(String texto, {VoidCallback? onTap, IconData? icone, required ColorScheme cores}) {
    if (texto.isEmpty && icone == null) {
      return const SizedBox(width: 72, height: 72); // Espaço vazio para manter o alinhamento
    }
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cores.surface,
        ),
        alignment: Alignment.center,
        child: icone != null
            ? Icon(icone, size: 28, color: cores.onSurface)
            : Text(texto, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Recebe o cuidador vindo da navegação da tela anterior
    final cuidador = ModalRoute.of(context)!.settings.arguments as Cuidador;
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Login',
                style: textos.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Insira seu código de acesso',
                style: textos.bodyLarge?.copyWith(color: cores.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: cores.primaryContainer,
                    foregroundColor: cores.onPrimaryContainer,
                    child: Text(
                      cuidador.iniciais,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    cuidador.nome,
                    style: textos.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              Text(
                'PIN',
                textAlign: TextAlign.center,
                style: textos.labelMedium?.copyWith(color: cores.onSurfaceVariant, fontWeight: FontWeight.w600, letterSpacing: 0.8),
              ),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 4; i++) ...[
                    _buildBolinha(i < _pinAtual.length, cores),
                    if (i < 3) const SizedBox(width: 16),
                  ],
                ],
              ),
              if (_erro != null) ...[
                const SizedBox(height: 16),
                Text(_erro!, textAlign: TextAlign.center, style: TextStyle(color: cores.error, fontWeight: FontWeight.w500)),
              ],
              
              const Spacer(), // Empurra o teclado para o rodapé
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTecla('1', onTap: () => _digitar('1'), cores: cores),
                  _buildTecla('2', onTap: () => _digitar('2'), cores: cores),
                  _buildTecla('3', onTap: () => _digitar('3'), cores: cores),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTecla('4', onTap: () => _digitar('4'), cores: cores),
                  _buildTecla('5', onTap: () => _digitar('5'), cores: cores),
                  _buildTecla('6', onTap: () => _digitar('6'), cores: cores),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTecla('7', onTap: () => _digitar('7'), cores: cores),
                  _buildTecla('8', onTap: () => _digitar('8'), cores: cores),
                  _buildTecla('9', onTap: () => _digitar('9'), cores: cores),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTecla('', cores: cores),
                  _buildTecla('0', onTap: () => _digitar('0'), cores: cores),
                  _buildTecla('', icone: Icons.backspace_outlined, onTap: _apagar, cores: cores),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // O botão de entrar
              FilledButton(
                // Se o PIN não tiver 4 dígitos, passamos null (o botão desabilita sozinho)
                onPressed: _pinAtual.length == 4 ? () => _entrar(cuidador) : null,
                child: const Text('Entrar'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}