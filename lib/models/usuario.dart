class Usuario {
  final String id;
  final String email;
  final String? nombre;
  final String rol; // 'Admin' | 'Supervisor' | 'Tecnico'

  const Usuario({
    required this.id,
    required this.email,
    this.nombre,
    this.rol = 'Tecnico',
  });
}
