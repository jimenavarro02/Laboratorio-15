// lib/services/sync_service.dart
import 'dart:io';

import 'package:http/http.dart' as http;

import '../data/database_helper.dart';

class SyncService {
  final String backendUrl;
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  SyncService({required this.backendUrl});

  Future<int> ejecutarSincronizacion(String codigoTecnico) async {
    final List<Map<String, dynamic>> pendientes =
        await dbHelper.obtenerPendientes();
    if (pendientes.isEmpty) return 0;

    int enviadasConExito = 0;

    for (final inc in pendientes) {
      final int localId = inc['id'] as int;
      final uri = Uri.parse('$backendUrl/api/v1/incidencias');
      final request = http.MultipartRequest('POST', uri);

      request.fields['titulo'] = inc['titulo'] as String;
      request.fields['descripcion'] = inc['descripcion'] as String;
      request.fields['categoria'] = inc['categoria'] as String;
      request.fields['latitud'] = inc['latitud'].toString();
      request.fields['longitud'] = inc['longitud'].toString();
      request.fields['tecnicoCodigo'] = codigoTecnico;

      final String? rutaFoto = inc['foto_path'] as String?;
      if (rutaFoto != null && File(rutaFoto).existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath('foto', rutaFoto),
        );
      }

      try {
        final streamedRes = await request.send().timeout(
              const Duration(seconds: 15),
            );

        if (streamedRes.statusCode == 200 || streamedRes.statusCode == 201) {
          await dbHelper.marcarSincronizado(localId);
          enviadasConExito++;
        }
      } catch (e) {
        // En caso de corte de señal, interrumpimos la cola para reintentar luego
        break;
      }
    }

    return enviadasConExito;
  }
}
