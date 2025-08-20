import 'pieza.dart';

class Pedestal {
  final String id;      // UUID/string por ahora
  final String codigo;  // ID visible: ej. "N-6"
  String? muelle; // muelle guardado como texto (permite números o códigos)
  String barco; // nombre o identificador del barco que estuvo/en el pedestal
  List<Pieza> piezas;

  Pedestal({
    required this.id,
    required this.codigo,
    this.muelle,
    this.barco = '',
    this.piezas = const [],
  }){
    // asegurar lista mutable
    piezas = List<Pieza>.from(piezas);
  }

  Pedestal copyWith({
    String? id, String? codigo, String? muelle, String? barco, List<Pieza>? piezas
  }) => Pedestal(
    id: id ?? this.id,
    codigo: codigo ?? this.codigo,
    muelle: muelle ?? this.muelle,
    barco: barco ?? this.barco,
    piezas: piezas ?? this.piezas,
  );

  factory Pedestal.fromJson(Map<String, dynamic> json) {
    return Pedestal(
      id: json['id'],
      codigo: json['codigo'],
      muelle: json['muelle'] != null ? json['muelle'].toString() : null,
      barco: json['barco'] ?? '',
      piezas: json['piezas'] != null
          ? (json['piezas'] as List).map((e) => Pieza.fromJson(e)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'muelle': muelle,
      'barco': barco,
      'piezas': piezas.map((p) => p.toJson()).toList(),
    };
  }
}
