import 'package:fieldtech_mobile/models/filtro_incidencias.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FiltroIncidencias', () {
    test('define tres opciones en el orden esperado', () {
      expect(FiltroIncidencias.values.length, 3);
      expect(FiltroIncidencias.values.first, FiltroIncidencias.todas);
    });

    test('Todas no aplica WHERE (valor nulo)', () {
      expect(FiltroIncidencias.todas.valorSincronizado, isNull);
    });

    test('Offline consulta is_synced = 0 y Sincronizadas is_synced = 1', () {
      expect(FiltroIncidencias.offline.valorSincronizado, 0);
      expect(FiltroIncidencias.sincronizadas.valorSincronizado, 1);
    });
  });
}
