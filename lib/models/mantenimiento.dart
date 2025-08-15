enum TipoIntervencion { adicion, eliminacion, cambio }

String tipoToText(TipoIntervencion t) {
  switch (t) {
    case TipoIntervencion.adicion: return 'Adición';
    case TipoIntervencion.eliminacion: return 'Eliminación';
    case TipoIntervencion.cambio: return 'Cambio';
  }
}

class Mantenimiento {
  final String id;
  final String pedestalId;
  final DateTime fecha;
  final String tecnicoEmail;
  final TipoIntervencion tipo;
  final String detalle;

  const Mantenimiento({
    required this.id,
    required this.pedestalId,
    required this.fecha,
    required this.tecnicoEmail,
    required this.tipo,
    required this.detalle,
  });
}
