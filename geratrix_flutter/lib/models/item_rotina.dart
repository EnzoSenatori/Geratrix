import '../dados/dados_exemplo.dart';
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

  // Monta o item a partir do JSON de /api/lista; residente e natureza da tela vêm dos dados de exemplo pelo id
  factory ItemRotina.deJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final residenteId = json['residente_id'] as String;
    final nomeResidente = json['residente'] as String;

    // O banco só conhece 'tarefa' e 'medicao'; o app também abre telas de 'medicacao' e 'exercicio'
    ItemRotina? exemplo;
    for (final item in itensDoDia) {
      if (item.id == id) exemplo = item;
    }

    return ItemRotina(
      id: id,
      horario: json['horario'] as String,
      tipo: json['tipo'] as String,
      natureza: exemplo?.natureza ?? json['natureza'] as String,
      residente: residentesPorId[residenteId] ?? _residenteMinimo(residenteId, nomeResidente),
      status: json['status'] as String,
      unidade: json['unidade'] as String?,
      faixaMin: (json['faixa_min'] as num?)?.toDouble(),
      faixaMax: (json['faixa_max'] as num?)?.toDouble(),
    );
  }

  // Residente sem prontuário nos dados de exemplo: só nome e iniciais, para as telas abrirem sem quebrar
  static Residente _residenteMinimo(String id, String nome) {
    final partes = nome.split(' ').where((p) => p.isNotEmpty).toList();
    final iniciais = partes.take(2).map((p) => p[0].toUpperCase()).join();
    return Residente(
      id: id,
      nome: nome,
      quarto: '',
      iniciais: iniciais,
      alergias: const [],
      restricoesAlimentares: const [],
      contatoEmergencia: '',
      observacoesMedicas: '',
    );
  }

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