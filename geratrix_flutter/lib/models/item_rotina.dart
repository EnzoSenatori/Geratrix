import 'residente.dart';

// Uma tarefa da rotina do dia; unidade e faixa só valem quando a natureza é 'medicao'
class ItemRotina {
  final String id;
  final String horario;
  final String tipo; // nome do tipo, como no tipo_checkin do backend
  final String natureza; // 'tarefa', 'medicacao', 'medicao' ou 'exercicio'
  final Residente residente;
  final String status; // 'atrasado', 'pendente', 'feito' ou 'nao_realizado'
  final String? unidade;
  final double? faixaMin;
  final double? faixaMax;

  const ItemRotina({
    required this.id,
    required this.horario,
    required this.tipo,
    required this.natureza,
    required this.residente,
    required this.status,
    this.unidade,
    this.faixaMin,
    this.faixaMax,
  });

  // Indica se o item já tem registro no turno, feito ou não realizado, como no backend
  bool get registrado => status == 'feito' || status == 'nao_realizado';

  // Cria uma cópia com outro status; o model é imutável, então a lista troca o item inteiro
  ItemRotina comStatus(String novoStatus) {
    return ItemRotina(
      id: id,
      horario: horario,
      tipo: tipo,
      natureza: natureza,
      residente: residente,
      status: novoStatus,
      unidade: unidade,
      faixaMin: faixaMin,
      faixaMax: faixaMax,
    );
  }
}