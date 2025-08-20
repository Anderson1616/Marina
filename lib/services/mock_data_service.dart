import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/pedestal.dart';
import '../models/mantenimiento.dart';
import '../models/pieza.dart';
import 'auth_service.dart';

class MockDataService extends ChangeNotifier {
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

  // ==== PIEZAS: lectura/modificación ====
  List<Pieza> piezasDePedestal(String pedestalId) {
    final p = _pedestales.firstWhere((e) => e.id == pedestalId, orElse: () => Pedestal(id: '', codigo: ''));
    return List.unmodifiable(p.piezas);
  }

  Future<Pieza> agregarPieza({
    required String pedestalId,
    required String nombre,
    bool registrarMantenimiento = false,
    String? tecnicoEmailOverride,
  }) async {
    final pedestal = _pedestales.firstWhere((p) => p.id == pedestalId);
    if (pedestal.piezas.any((pz) => pz.nombre.toLowerCase() == nombre.trim().toLowerCase())) {
      throw Exception('Ya existe una pieza con ese nombre en este pedestal');
    }
    final pieza = Pieza(id: DateTime.now().microsecondsSinceEpoch.toString(), nombre: nombre.trim(), creadaEn: DateTime.now());
    pedestal.piezas.add(pieza);
    notifyListeners();

    if (registrarMantenimiento) {
      await agregarMantenimiento(
        pedestalId: pedestalId,
        tipo: TipoIntervencion.adicion,
        detalle: 'Adición de pieza ${pieza.nombre}',
        fecha: DateTime.now(),
        barco: pedestal.barco,
        piezaId: pieza.id,
        piezaNombre: pieza.nombre,
      );
    }

    return pieza;
  }

  Future<void> eliminarPieza({
    required String pedestalId,
    required String piezaId,
    bool registrarMantenimiento = false,
    String? tecnicoEmailOverride,
  }) async {
    final pedestal = _pedestales.firstWhere((p) => p.id == pedestalId);
    final idx = pedestal.piezas.indexWhere((pz) => pz.id == piezaId);
    if (idx == -1) return;
    final removed = pedestal.piezas.removeAt(idx);
    notifyListeners();

    if (registrarMantenimiento) {
      await agregarMantenimiento(
        pedestalId: pedestalId,
        tipo: TipoIntervencion.eliminacion,
        detalle: 'Eliminación de pieza ${removed.nombre}',
        fecha: DateTime.now(),
        barco: pedestal.barco,
        piezaId: removed.id,
        piezaNombre: removed.nombre,
      );
    }
  }

  Future<Pieza> editarPieza({
    required String pedestalId,
    required String piezaId,
    required String nuevoNombre,
    bool registrarMantenimiento = false,
    String? tecnicoEmailOverride,
  }) async {
    final pedestal = _pedestales.firstWhere((p) => p.id == pedestalId);
    final pieza = pedestal.piezas.firstWhere((pz) => pz.id == piezaId);
    final viejoNombre = pieza.nombre;
    pieza.nombre = nuevoNombre;
    notifyListeners();

    if (registrarMantenimiento) {
      await agregarMantenimiento(
        pedestalId: pedestalId,
        tipo: TipoIntervencion.cambio,
        detalle: 'Cambio de pieza: $viejoNombre -> $nuevoNombre',
        fecha: DateTime.now(),
        barco: pedestal.barco,
        piezaId: pieza.id,
        piezaNombre: nuevoNombre,
      );
    }

    return pieza;
  }

  // =============== NUEVO: CRUD DE PEDESTALES ===============

  /// Crea un pedestal nuevo (validando código obligatorio y no duplicado).
  Future<Pedestal> crearPedestal({
    required String codigo,
    String? muelle,
    String? barco
  }) async {
    final cod = codigo.trim().toUpperCase();
    if (cod.isEmpty) {
      throw Exception('El código es obligatorio');
    }

    if (_pedestales.any((p) => p.codigo.toUpperCase() == cod)) {
      throw Exception('Ya existe un pedestal con ese código');
    }

    final nuevo = Pedestal(
      id: (Random().nextInt(1 << 31)).toString(),
      codigo: cod,
      muelle: (muelle ?? '').trim().isEmpty ? null : muelle!.trim(),
      barco: (barco ?? '').trim(),
    );
    _pedestales.add(nuevo);
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 150));
    return nuevo;
  }

  /// Elimina un pedestal y su historial mock.
  Future<void> eliminarPedestal(String pedestalId) async {
    _mantenimientos.removeWhere((m) => m.pedestalId == pedestalId);
    _pedestales.removeWhere((p) => p.id == pedestalId);
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 100));
  }

  // Agrega o actualiza un pedestal existente por id
  void updatePedestal(Pedestal updated) {
    final index = _pedestales.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _pedestales[index] = updated;
      notifyListeners();
    }
  }

  // Obtener pedestal por id
  Pedestal? getPedestalById(String id) {
    for (var p in _pedestales) {
      if (p.id == id) return p;
    }
    return null;
  }

  // Ajustar agregarMantenimiento existente para manejar piezaId/piezaNombre
  Future<void> agregarMantenimiento({
    required String pedestalId,
    required TipoIntervencion tipo,
    required String detalle,
    DateTime? fecha,
    String? barco,
    String? piezaId,
    String? piezaNombre,
  }) async {
    final email = AuthService.usuarioActual?.email ?? 'tecnico@demo.cr';
    final id = (Random().nextInt(1 << 31)).toString();

    // Antes de agregar el mantenimiento, sincronizar piezas según tipo
    final pedestal = _pedestales.firstWhere((p) => p.id == pedestalId);
    if (tipo == TipoIntervencion.adicion) {
      if (piezaId == null) {
        // crear pieza nueva con piezaNombre
        if (piezaNombre != null && piezaNombre.trim().isNotEmpty) {
          if (!pedestal.piezas.any((pz) => pz.nombre.toLowerCase() == piezaNombre.trim().toLowerCase())) {
            pedestal.piezas.add(Pieza(id: DateTime.now().microsecondsSinceEpoch.toString(), nombre: piezaNombre.trim(), creadaEn: DateTime.now()));
          }
        }
      }
    } else if (tipo == TipoIntervencion.eliminacion) {
      if (piezaId != null) {
        final idx = pedestal.piezas.indexWhere((pz) => pz.id == piezaId);
        if (idx != -1) pedestal.piezas.removeAt(idx);
      } else if (piezaNombre != null) {
        final idx = pedestal.piezas.indexWhere((pz) => pz.nombre.toLowerCase() == piezaNombre.trim().toLowerCase());
        if (idx != -1) pedestal.piezas.removeAt(idx);
      }
    } else if (tipo == TipoIntervencion.cambio) {
      if (piezaId != null && piezaNombre != null) {
        final pz = pedestal.piezas.firstWhere((pz) => pz.id == piezaId, orElse: () => Pieza(id: '', nombre: '', creadaEn: DateTime.now()));
        if (pz.id.isNotEmpty) pz.nombre = piezaNombre;
      }
    }

    _mantenimientos.add(Mantenimiento(
      id: id,
      pedestalId: pedestalId,
      fecha: fecha ?? DateTime.now(),
      tecnicoEmail: email,
      tipo: tipo,
      detalle: detalle,
      barco: barco ?? pedestal.barco,
      piezaId: piezaId,
      piezaNombre: piezaNombre,
    ));

    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 150));
  }
}
