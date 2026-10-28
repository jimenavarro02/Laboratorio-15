// lib/screens/incidencias_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../data/database_helper.dart';
import '../models/filtro_incidencias.dart';
import '../services/hardware_service.dart';
import '../services/sync_service.dart';

class IncidenciasScreen extends StatefulWidget {
  const IncidenciasScreen({super.key});

  @override
  State<IncidenciasScreen> createState() => _IncidenciasScreenState();
}

class _IncidenciasScreenState extends State<IncidenciasScreen> {
  // 10.0.2.2 apunta a la máquina anfitriona desde el emulador de Android.
  // En un teléfono real use la IP privada de su PC (ej. http://192.168.1.45:8080)
  final SyncService _syncService = SyncService(
    backendUrl: 'http://10.0.2.2:8080',
  );

  List<Map<String, dynamic>> _incidencias = [];
  FiltroIncidencias _filtro = FiltroIncidencias.todas;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarIncidenciasLocales();
  }

  Future<void> _cargarIncidenciasLocales() async {
    final datos = await DatabaseHelper.instance.obtenerPorFiltro(_filtro);
    if (!mounted) return;
    setState(() => _incidencias = datos);
  }

  Future<void> _sincronizar() async {
    setState(() => _cargando = true);
    final total = await _syncService.ejecutarSincronizacion('TEC-CR-001');
    await _cargarIncidenciasLocales();
    if (!mounted) return;
    setState(() => _cargando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          total > 0
              ? '¡Sincronización exitosa! ($total registros enviados).'
              : 'No hay registros pendientes o el servidor no respondió.',
        ),
        backgroundColor: total > 0 ? Colors.green[700] : Colors.orange[800],
      ),
    );
  }

  void _abrirFormularioModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => NuevaIncidenciaModal(
        onGuardado: _cargarIncidenciasLocales,
      ),
    );
  }

  String get _mensajeVacio {
    switch (_filtro) {
      case FiltroIncidencias.todas:
        return 'No hay inspecciones registradas.\nPresione + para crear una.';
      case FiltroIncidencias.offline:
        return 'No hay inspecciones pendientes de sincronizar.';
      case FiltroIncidencias.sincronizadas:
        return 'Aún no hay inspecciones sincronizadas.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FieldTech Inspecciones'),
        actions: [
          IconButton(
            icon: _cargando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            tooltip: 'Sincronizar con Servidor',
            onPressed: _cargando ? null : _sincronizar,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Reto Autónomo: filtro segmentado bajo el AppBar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<FiltroIncidencias>(
                  showSelectedIcon: false,
                  segments: FiltroIncidencias.values
                      .map(
                        (f) => ButtonSegment<FiltroIncidencias>(
                          value: f,
                          label: Text(f.etiqueta),
                        ),
                      )
                      .toList(),
                  selected: <FiltroIncidencias>{_filtro},
                  onSelectionChanged: (Set<FiltroIncidencias> seleccion) {
                    setState(() => _filtro = seleccion.first);
                    _cargarIncidenciasLocales();
                  },
                ),
              ),
            ),
            Expanded(
              child: _incidencias.isEmpty
                  ? Center(
                      child: Text(
                        _mensajeVacio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 90),
                      itemCount: _incidencias.length,
                      itemBuilder: (ctx, index) {
                        final item = _incidencias[index];
                        final bool sincronizado = item['is_synced'] == 1;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: sincronizado
                                  ? Colors.green[100]
                                  : Colors.amber[100],
                              child: Icon(
                                sincronizado
                                    ? Icons.cloud_done
                                    : Icons.cloud_off,
                                color: sincronizado
                                    ? Colors.green[800]
                                    : Colors.amber[900],
                              ),
                            ),
                            title: Text(
                              item['titulo'] as String,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${item['categoria']} | Lat: ${item['latitud']}, '
                              'Lon: ${item['longitud']}',
                            ),
                            trailing: Text(
                              sincronizado ? 'En Servidor' : 'Offline',
                              style: TextStyle(
                                fontSize: 12,
                                color: sincronizado
                                    ? Colors.green[700]
                                    : Colors.amber[900],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormularioModal,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Nueva Incidencia'),
      ),
    );
  }
}

class NuevaIncidenciaModal extends StatefulWidget {
  final VoidCallback onGuardado;

  const NuevaIncidenciaModal({super.key, required this.onGuardado});

  @override
  State<NuevaIncidenciaModal> createState() => _NuevaIncidenciaModalState();
}

class _NuevaIncidenciaModalState extends State<NuevaIncidenciaModal> {
  final _tituloController = TextEditingController();
  final _descController = TextEditingController();
  final HardwareService _hardware = HardwareService();

  String _categoria = 'INFRAESTRUCTURA';
  Position? _posicion;
  File? _foto;
  bool _obteniendoGps = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _capturarGPS() async {
    setState(() => _obteniendoGps = true);
    try {
      final pos = await _hardware.capturarUbicacionGPS();
      if (!mounted) return;
      setState(() => _posicion = pos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _obteniendoGps = false);
    }
  }

  Future<void> _capturarCamara() async {
    final imagen = await _hardware.tomarFotografia();
    if (imagen != null && mounted) {
      setState(() => _foto = imagen);
    }
  }

  Future<void> _guardarEnSQLite() async {
    if (_tituloController.text.trim().isEmpty || _posicion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Debe ingresar un título y capturar las coordenadas GPS.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final row = {
      'titulo': _tituloController.text.trim(),
      'descripcion': _descController.text.trim(),
      'categoria': _categoria,
      'latitud': _posicion!.latitude,
      'longitud': _posicion!.longitude,
      'foto_path': _foto?.path,
      'is_synced': 0,
      'fecha_creacion': DateTime.now().toIso8601String(),
    };

    await DatabaseHelper.instance.insertar(row);
    widget.onGuardado();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Registrar Incidencia en Campo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Título de la Incidencia',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción técnica',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _categoria,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(
                  value: 'INFRAESTRUCTURA',
                  child: Text('Infraestructura'),
                ),
                DropdownMenuItem(
                  value: 'RED_ACCESO',
                  child: Text('Red de Acceso'),
                ),
                DropdownMenuItem(
                  value: 'TORRE_RADIO',
                  child: Text('Torre de Radio'),
                ),
              ],
              onChanged: (v) => setState(() => _categoria = v ?? _categoria),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _obteniendoGps ? null : _capturarGPS,
                    icon: _obteniendoGps
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(
                      _posicion != null
                          ? 'GPS: ${_posicion!.latitude.toStringAsFixed(3)}, '
                              '${_posicion!.longitude.toStringAsFixed(3)}'
                          : 'Obtener GPS',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: _capturarCamara,
                  icon: const Icon(Icons.camera_alt),
                  tooltip: 'Tomar Fotografía',
                ),
              ],
            ),
            if (_foto != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_foto!, height: 120, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _guardarEnSQLite,
              child: const Text('Guardar Localmente (Offline)'),
            ),
          ],
        ),
      ),
    );
  }
}
