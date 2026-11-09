// Modelo para o registro histórico de um turno de trabalho
class TurnoHistorico {
  final String data;
  final String cuidador;
  final String turno;
  final int concluidas;
  final int naoRealizadas;
  final String observacoes;

  const TurnoHistorico({
    required this.data,
    required this.cuidador,
    required this.turno,
    required this.concluidas,
    required this.naoRealizadas,
    required this.observacoes,
  });
}