class Pedestal {
  final String id;      // UUID/string por ahora
  final String codigo;  // ID visible: ej. "N-6"
  final String? muelle; // N, S, etc.
  final String? ubicacion;

  const Pedestal({
    required this.id,
    required this.codigo,
    this.muelle,
    this.ubicacion,
  });
}
