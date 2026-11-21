// Resumo de uma série, enviado pela caneleira dentro do tópico sessao/<sid>
class SerieExercicio {
  final int numero;
  final int validas;
  final int total;
  final double admMedia; // graus
  final double velPico; // graus por segundo
  final int desviosAdm; // repetições abaixo da ADM mínima
  final int desviosVel; // repetições acima da velocidade máxima
  final double tempoSubida; // segundos, fase concêntrica
  final double tempoDescida; // segundos, fase excêntrica

  const SerieExercicio({
    required this.numero,
    required this.validas,
    required this.total,
    required this.admMedia,
    required this.velPico,
    required this.desviosAdm,
    required this.desviosVel,
    required this.tempoSubida,
    required this.tempoDescida,
  });

  // Cria a série a partir do JSON recebido, com os nomes do contrato
  factory SerieExercicio.fromJson(Map<String, dynamic> json) {
    final desvios = json['desvios'] as Map<String, dynamic>;
    return SerieExercicio(
      numero: json['n'] as int,
      validas: json['validas'] as int,
      total: json['total'] as int,
      admMedia: (json['adm_media'] as num).toDouble(),
      velPico: (json['vel_pico'] as num).toDouble(),
      desviosAdm: desvios['adm'] as int,
      desviosVel: desvios['vel'] as int,
      tempoSubida: (json['t_conc'] as num).toDouble(),
      tempoDescida: (json['t_exc'] as num).toDouble(),
    );
  }

  // Texto da coluna "Status" da tabela de séries, como no mockup ("2 abaixo da ADM")
  String get status {
    if (desviosAdm == 0 && desviosVel == 0) return 'OK';
    final partes = <String>[];
    if (desviosAdm > 0) partes.add('$desviosAdm abaixo da ADM');
    if (desviosVel > 0) partes.add('$desviosVel acima da velocidade');
    return partes.join(' e ');
  }
}