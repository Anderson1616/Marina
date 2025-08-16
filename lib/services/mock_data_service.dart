import 'dart:math';
import '../models/pedestal.dart';
import '../models/mantenimiento.dart';
import 'auth_service.dart';

class MockDataService {
  static final MockDataService _inst = MockDataService._internal();
  factory MockDataService() => _inst;
  MockDataService._internal() {
    
  }

  final List<Pedestal> _pedestales = [];
  final List<Mantenimiento> _mantenimientos = [];

  // === LISTAR (con filtro por código) ===
  List<Pedestal> listarPedestales({String? filtro}) {
    if (filtro == null || filtro.trim().isEmpty) {
      return List.unmodifiable(_pedestales);
    }
    final f = filtro.toUpperCase();
    return _pedestales.where((p) => p.codigo.toUpperCase().contains(f)).toList();
  }

  // === HISTORIAL DE MANTENIMIENTOS (por pedestal) ===
  List<Mantenimiento> mantenimientosPorPedestal(String pedestalId) {
    final list = _mantenimientos.where((m) => m.pedestalId == pedestalId).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    return list;
  }

  // === AGREGAR MANTENIMIENTO (mock) ===
  Future<void> agregarMantenimiento({
    required String pedestalId,
    required TipoIntervencion tipo,
    required String detalle,
    DateTime? fecha,
  }) async {
    final email = AuthService.usuarioActual?.email ?? 'tecnico@demo.cr';
    final id = (Random().nextInt(1 << 31)).toString();
    _mantenimientos.add(Mantenimiento(
      id: id,
      pedestalId: pedestalId,
      fecha: fecha ?? DateTime.now(),
      tecnicoEmail: email,
      tipo: tipo,
      detalle: detalle,
    ));
    await Future.delayed(const Duration(milliseconds: 150));
  }

  // =============== NUEVO: CRUD DE PEDESTALES ===============

  /// Crea un pedestal nuevo (validando código obligatorio y no duplicado).
  Future<Pedestal> crearPedestal({
    required String codigo,
    String? muelle,
    String? ubicacion,
  }) async {
    final cod = codigo.trim().toUpperCase();
    if (cod.isEmpty) {
      throw Exception('El código es obligatorio');
    }
    // (Opcional) Validar formato ej. N-6
    // final regex = RegExp(r'^[A-Z]-\d+$');
    // if (!regex.hasMatch(cod)) throw Exception('Código inválido. Usa formato LETRA-NÚMERO (ej. N-6)');

    if (_pedestales.any((p) => p.codigo.toUpperCase() == cod)) {
      throw Exception('Ya existe un pedestal con ese código');
    }

    final nuevo = Pedestal(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      codigo: cod,
      muelle: (muelle ?? '').trim().isEmpty ? null : muelle!.trim(),
      ubicacion: (ubicacion ?? '').trim().isEmpty ? null : ubicacion!.trim(),
    );
    _pedestales.add(nuevo);
    await Future.delayed(const Duration(milliseconds: 150));
    return nuevo;
  }

  /// Elimina un pedestal y su historial mock.
  Future<void> eliminarPedestal(String pedestalId) async {
    _mantenimientos.removeWhere((m) => m.pedestalId == pedestalId);
    _pedestales.removeWhere((p) => p.id == pedestalId);
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
