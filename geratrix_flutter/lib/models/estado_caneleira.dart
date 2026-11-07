// Estado que a caneleira publica (retido) no tópico estado
class EstadoCaneleira {
  final bool online;
  final int? bateria; // %
  final int? rssi; // dBm, força do sinal Wi-Fi
  final bool? emUso; // caneleira presa à perna
  final String? sid; // sessão em andamento

  const EstadoCaneleira({
    required this.online,
    this.bateria,
    this.rssi,
    this.emUso,
    this.sid,
  });

  // Cria o estado a partir do JSON recebido, com os nomes do contrato
  factory EstadoCaneleira.fromJson(Map<String, dynamic> json) {
    return EstadoCaneleira(
      online: json['online'] == true,
      bateria: json['bat'] as int?,
      rssi: json['rssi'] as int?,
      emUso: json['uso'] as bool?,
      sid: json['sid'] as String?,
    );
  }

  // Qualidade do sinal em texto, como no mockup ("Sinal bom")
  String get sinal {
    final valor = rssi;
    if (valor == null) return 'Sinal desconhecido';
    if (valor >= -67) return 'Sinal bom';
    if (valor >= -80) return 'Sinal regular';
    return 'Sinal fraco';
  }
}