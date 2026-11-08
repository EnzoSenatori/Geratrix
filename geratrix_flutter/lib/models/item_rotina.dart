// Modelo que representa uma tarefa do plantão
class ItemRotina {
  final String id;
  final String horario;
  final String tipo;
  final String residente;
  final String status; // 'atrasado', 'pendente', 'feito'

  const ItemRotina(this.id, this.horario, this.tipo, this.residente, this.status);
}