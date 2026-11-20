// Representa um cuidador que pode abrir o turno; o PIN nunca fica no app, só no backend
class Cuidador {
  final int id;
  final String nome;
  final String iniciais; // "TCM", "RC" e "ES"
  final String turnoPadrao;
  final bool ativo;

  const Cuidador({
    required this.id,
    required this.nome,
    required this.iniciais,
    required this.turnoPadrao,
    this.ativo = true, // opcional (sem required), com padrão sendo "true"
  });

  // Monta o cuidador a partir do JSON da API (/api/cuidadores, /api/login)
  factory Cuidador.deJson(Map<String, dynamic> json) {
    return Cuidador(
      id: json['id'] as int,
      nome: json['nome'] as String,
      iniciais: json['iniciais'] as String,
      turnoPadrao: json['turno_padrao'] as String,
    );
  }
}
