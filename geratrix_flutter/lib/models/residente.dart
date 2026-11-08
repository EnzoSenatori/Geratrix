// Modelo que representa os dados do prontuário rápido do residente
class Residente {
  final String id;
  final String nome;
  final String quarto;
  final String iniciais;
  final List<String> alergias;
  final List<String> restricoesAlimentares;
  final String contatoEmergencia;
  final String observacoesMedicas;

  const Residente({
    required this.id,
    required this.nome,
    required this.quarto,
    required this.iniciais,
    required this.alergias,
    required this.restricoesAlimentares,
    required this.contatoEmergencia,
    required this.observacoesMedicas,
  });
}