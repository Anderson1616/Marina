class Pieza {
  final String id;
  String nombre;
  final DateTime creadaEn;

  Pieza({required this.id, required this.nombre, required this.creadaEn});

  Pieza copyWith({String? id, String? nombre, DateTime? creadaEn}) =>
      Pieza(id: id ?? this.id, nombre: nombre ?? this.nombre, creadaEn: creadaEn ?? this.creadaEn);

  factory Pieza.fromJson(Map<String, dynamic> json) {
    return Pieza(
      id: json['id'],
      nombre: json['nombre'],
      creadaEn: DateTime.parse(json['creadaEn']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'creadaEn': creadaEn.toIso8601String(),
    };
  }
}
