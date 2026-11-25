class Clima {
  const Clima({
    required this.temperatura,
    required this.codigo,
    required this.local,
    required this.obtidoEm,
  });

  final double temperatura;

  /// Código WMO devolvido pela Open-Meteo.
  final int codigo;
  final String local;
  final DateTime obtidoEm;

  /// Converte a resposta de `/v1/forecast?current=temperature_2m,weather_code`.
  /// Lança [FormatException] se o JSON não tiver o formato esperado.
  factory Clima.fromOpenMeteo(
    Map<String, dynamic> json, {
    required String local,
    DateTime? agora,
  }) {
    final atual = json['current'];
    if (atual is! Map) throw const FormatException('Campo "current" ausente');
    final temperatura = atual['temperature_2m'];
    final codigo = atual['weather_code'];
    if (temperatura is! num || codigo is! num) {
      throw const FormatException('Temperatura ou código ausente');
    }
    return Clima(
      temperatura: temperatura.toDouble(),
      codigo: codigo.toInt(),
      local: local,
      obtidoEm: agora ?? DateTime.now(),
    );
  }

  // Formato usado no cache local.

  Map<String, dynamic> toJson() => {
        'temperatura': temperatura,
        'codigo': codigo,
        'local': local,
        'obtidoEm': obtidoEm.millisecondsSinceEpoch,
      };

  factory Clima.fromJson(Map<String, dynamic> json) => Clima(
        temperatura: (json['temperatura'] as num).toDouble(),
        codigo: (json['codigo'] as num).toInt(),
        local: json['local'] as String,
        obtidoEm: DateTime.fromMillisecondsSinceEpoch(
          (json['obtidoEm'] as num).toInt(),
        ),
      );

  String get descricao {
    if (codigo == 0) return 'céu limpo';
    if (codigo <= 2) return 'parcialmente nublado';
    if (codigo == 3) return 'nublado';
    if (codigo == 45 || codigo == 48) return 'neblina';
    if (codigo >= 51 && codigo <= 57) return 'garoa';
    if (codigo >= 61 && codigo <= 67) return 'chuva';
    if (codigo >= 71 && codigo <= 77) return 'neve';
    if (codigo >= 80 && codigo <= 82) return 'pancadas de chuva';
    if (codigo >= 95) return 'trovoada';
    return 'tempo indefinido';
  }
}
