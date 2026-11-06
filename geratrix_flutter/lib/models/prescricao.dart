class Prescricao {
  final String sid; // identificador anônimo da sessão, sem "/" nem "+"
  final int series;
  final int reps;
  final double admMin; // graus
  final double velMax; // graus por segundo
  final int descanso; // segundos

  const Prescricao({
    required this.sid,
    required this.series,
    required this.reps,
    required this.admMin,
    required this.velMax,
    required this.descanso,
  });

  // Converte para o formato do contrato MQTT, com os nomes que a caneleira espera
  Map<String, dynamic> toJson() {
    return {
      'sid': sid,
      'series': series,
      'reps': reps,
      'adm_min': admMin,
      'vel_max': velMax,
      'descanso': descanso,
    };
  }
}