import 'package:diario_atividades/models/atividade.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validação da atividade', () {
    test('distância aceita vírgula decimal', () {
      expect(Atividade.validarDistancia('5,2'), isNull);
      expect(Atividade.lerDistancia('5,2'), 5.2);
    });

    test('distância vazia, zero, negativa ou acima de 500 é recusada', () {
      expect(Atividade.validarDistancia(''), isNotNull);
      expect(Atividade.validarDistancia('abc'), isNotNull);
      expect(Atividade.validarDistancia('0'), isNotNull);
      expect(Atividade.validarDistancia('-3'), isNotNull);
      expect(Atividade.validarDistancia('501'), isNotNull);
    });

    test('duração precisa ser inteira entre 1 e 1440 minutos', () {
      expect(Atividade.validarDuracao('30'), isNull);
      expect(Atividade.validarDuracao('0'), isNotNull);
      expect(Atividade.validarDuracao('12,5'), isNotNull);
      expect(Atividade.validarDuracao('1441'), isNotNull);
    });
  });

  test('toMap e fromMap preservam os dados da atividade', () {
    final original = Atividade(
      tipo: 'Corrida',
      distanciaKm: 5.2,
      duracaoMin: 30,
      data: DateTime(2026, 11, 15, 21),
      local: 'Curitiba',
      temperatura: 24,
      condicao: 'nublado',
    );

    final copia = Atividade.fromMap('abc', original.toMap());

    expect(copia.id, 'abc');
    expect(copia.tipo, 'Corrida');
    expect(copia.distanciaKm, 5.2);
    expect(copia.duracaoMin, 30);
    expect(copia.data, original.data);
    expect(copia.local, 'Curitiba');
    expect(copia.temperatura, 24);
    expect(copia.condicao, 'nublado');
  });
}
