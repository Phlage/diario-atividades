class Atividade {
  const Atividade({
    this.id,
    required this.tipo,
    required this.distanciaKm,
    required this.duracaoMin,
    required this.data,
    this.local,
    this.temperatura,
    this.condicao,
  });

  static const tipos = ['Caminhada', 'Corrida', 'Ciclismo'];

  /// Id do documento no Firestore; nulo enquanto a atividade não foi criada.
  final String? id;
  final String tipo;
  final double distanciaKm;
  final int duracaoMin;
  final DateTime data;

  // Clima registrado no momento da atividade (opcional).
  final String? local;
  final double? temperatura;
  final String? condicao;

  Map<String, dynamic> toMap() => {
        'tipo': tipo,
        'distanciaKm': distanciaKm,
        'duracaoMin': duracaoMin,
        'data': data.millisecondsSinceEpoch,
        'local': local,
        'temperatura': temperatura,
        'condicao': condicao,
      };

  factory Atividade.fromMap(String id, Map<String, dynamic> m) => Atividade(
        id: id,
        tipo: m['tipo'] as String? ?? tipos.first,
        distanciaKm: (m['distanciaKm'] as num?)?.toDouble() ?? 0,
        duracaoMin: (m['duracaoMin'] as num?)?.toInt() ?? 0,
        data: DateTime.fromMillisecondsSinceEpoch(
          (m['data'] as num?)?.toInt() ?? 0,
        ),
        local: m['local'] as String?,
        temperatura: (m['temperatura'] as num?)?.toDouble(),
        condicao: m['condicao'] as String?,
      );

  // Regras de validação do formulário (aceitam vírgula decimal).

  static double? lerDistancia(String? texto) =>
      double.tryParse((texto ?? '').trim().replaceAll(',', '.'));

  static String? validarDistancia(String? texto) {
    final valor = lerDistancia(texto);
    if (valor == null) return 'Informe a distância em km.';
    if (valor <= 0 || valor > 500) {
      return 'A distância deve ser maior que 0 e até 500 km.';
    }
    return null;
  }

  static String? validarDuracao(String? texto) {
    final valor = int.tryParse((texto ?? '').trim());
    if (valor == null) return 'Informe a duração em minutos inteiros.';
    if (valor <= 0 || valor > 1440) {
      return 'A duração deve ficar entre 1 e 1440 minutos.';
    }
    return null;
  }
}
