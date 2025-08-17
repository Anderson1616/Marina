class Pedestal {
  final String id;      // UUID/string por ahora
  final String codigo;  // ID visible: ej. "N-6"
  int? muelle; // cambiar a int? para representar número de muelle o null
  String barco; // nombre o identificador del barco que estuvo/en el pedestal

  Pedestal({
    required this.id,
    required this.codigo,
    this.muelle,
    this.barco = '',
  });

  factory Pedestal.fromJson(Map<String, dynamic> json) {
    return Pedestal(
      id: json['id'],
      codigo: json['codigo'],
      muelle: json['muelle'] is int
          ? json['muelle'] as int
          : (json['muelle'] != null ? int.tryParse(json['muelle'].toString()) : null),
      barco: json['barco'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'muelle': muelle,
      'barco': barco,
    };
  }
}
