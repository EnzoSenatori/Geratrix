import 'serie_exercicio.dart';

// Resumo acumulado de uma sessão, publicado pela caneleira no tópico sessao/<sid>
class SessaoExercicio {
  final String sid;
  final String status; // aguardando, em_execucao, descanso ou concluida
  final List<SerieExercicio> series; // todas as séries concluídas até agora
  final int? ts; // horário em segundos Unix; nulo quando a caneleira não tem hora confiável

  const SessaoExercicio({
    required this.sid,
    required this.status,
    required this.series,
    this.ts,
  });

  // Cria a sessão a partir do JSON recebido, convertendo cada série da lista
  factory SessaoExercicio.fromJson(Map<String, dynamic> json) {
    final lista = json['series'] as List;
    return SessaoExercicio(
      sid: json['sid'] as String,
      status: json['status'] as String,
      series: lista
          .map((item) => SerieExercicio.fromJson(item as Map<String, dynamic>))
          .toList(),
      ts: json['ts'] as int?,
    );
  }

  // Indica se a caneleira já terminou todas as séries
  bool get concluida => status == 'concluida';

  // Status em texto para a tela, como no mockup ("Em execução")
  String get statusTexto {
    switch (status) {
      case 'em_execucao':
        return 'Em execução';
      case 'descanso':
        return 'Em descanso';
      case 'concluida':
        return 'Concluída';
      default:
        return 'Aguardando';
    }
  }
}