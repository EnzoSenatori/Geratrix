// Representa um cuidador que pode abrir o turno.
class Cuidador {
  final String nome;
  final String iniciais; // "TCM", "RC" e "ES"
  final String turnoPadrao;
  final String pin;
  final bool ativo;

  const Cuidador({
    required this.nome,
    required this.iniciais,
    required this.turnoPadrao,
    required this.pin,
    this.ativo = true, // opcional (sem required), com padrão sendo "true"
  });
}