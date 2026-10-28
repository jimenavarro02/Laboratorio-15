/// Opciones del filtro segmentado (Reto Autónomo).
/// [valorSincronizado] es el valor de la columna is_synced a consultar;
/// null significa "sin cláusula WHERE" (todas).
enum FiltroIncidencias {
  todas('Todas', null),
  offline('Offline', 0),
  sincronizadas('Sincronizadas', 1);

  const FiltroIncidencias(this.etiqueta, this.valorSincronizado);

  final String etiqueta;
  final int? valorSincronizado;
}
