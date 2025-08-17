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
  String barco; // barco que estaba en el pedestal cuando se registró el mantenimiento

  Mantenimiento({
    String? id,
    required this.pedestalId,
    required this.fecha,
    String? tecnicoEmail,
    required this.tipo,
    required this.detalle,
    this.barco = '',
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        tecnicoEmail = tecnicoEmail ?? '';

  factory Mantenimiento.fromJson(Map<String, dynamic> json) {
    return Mantenimiento(
      id: json['id'],
      pedestalId: json['pedestalId'],
      fecha: DateTime.parse(json['fecha']),
      tecnicoEmail: json['tecnicoEmail'],
      tipo: TipoIntervencion.values.firstWhere((e) => e.toString() == 'TipoIntervencion.${json['tipo']}'),
      detalle: json['detalle'],
      barco: json['barco'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pedestalId': pedestalId,
      'fecha': fecha.toIso8601String(),
      'tecnicoEmail': tecnicoEmail,
      'tipo': tipo.toString().split('.').last,
      'detalle': detalle,
      'barco': barco,
    };
  }
}
