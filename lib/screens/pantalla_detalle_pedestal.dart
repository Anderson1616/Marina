import 'package:flutter/material.dart';
import '../models/pedestal.dart';
import '../models/mantenimiento.dart';
import '../models/pieza.dart';
import '../services/mock_data_service.dart';
import 'pantalla_nuevo_mantenimiento.dart';

class PantallaDetallePedestal extends StatefulWidget {
  final Pedestal pedestal;
  const PantallaDetallePedestal({super.key, required this.pedestal});

  @override
  State<PantallaDetallePedestal> createState() => _PantallaDetallePedestalState();
}

class _PantallaDetallePedestalState extends State<PantallaDetallePedestal> {
  final _svc = MockDataService();
  late Pedestal _pedestal;

  // Datos
  List<Mantenimiento> _historialBase = [];
  List<Mantenimiento> _historial = [];

  // Filtros
  final _tecnicoCtrl = TextEditingController();
  final _barcoCtrl = TextEditingController();
  DateTime? _fechaFiltro;
  String _filtroBarco = '';

  @override
  void initState() {
    super.initState();
    _pedestal = _svc.getPedestalById(widget.pedestal.id) ?? widget.pedestal;
    _svc.addListener(_onData);
    _cargar();
  }

  void _onData() {
    setState(() {
      _pedestal = _svc.getPedestalById(widget.pedestal.id) ?? _pedestal;
      _cargar();
    });
  }

  @override
  void dispose() {
    _svc.removeListener(_onData);
    _tecnicoCtrl.dispose();
    _barcoCtrl.dispose();
    super.dispose();
  }

  void _cargar() {
    _historialBase = _svc.mantenimientosPorPedestal(_pedestal.id);
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    final t = _tecnicoCtrl.text.trim().toLowerCase();
    final f = _fechaFiltro;

    final res = _historialBase.where((m) {
      bool okTecnico = true;
      bool okFecha = true;
      bool okBarco = true;

      if (t.isNotEmpty) {
        okTecnico = m.tecnicoEmail.toLowerCase().contains(t);
      }

      if (f != null) {
        okFecha = m.fecha.year == f.year &&
            m.fecha.month == f.month &&
            m.fecha.day == f.day;
      }

      if (_filtroBarco.isNotEmpty) {
        final nombreBarco = (m.barco.isNotEmpty ? m.barco : _pedestal.barco).toLowerCase();
        okBarco = nombreBarco.contains(_filtroBarco);
      }

      return okTecnico && okFecha && okBarco;
    }).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    setState(() => _historial = res);
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _fechaFiltro ?? DateTime.now(),
    );
    if (picked != null) {
      setState(() => _fechaFiltro = picked);
      _aplicarFiltros();
    }
  }

  void _limpiarFiltros() {
    _tecnicoCtrl.clear();
    _barcoCtrl.clear();
    setState(() {
      _fechaFiltro = null;
      _filtroBarco = '';
    });
    _aplicarFiltros();
  }

  String _fmt(DateTime f) =>
      '${f.year}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')} '
      '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';

  PreferredSizeWidget _appBar(Pedestal p) {
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          Image.asset('assets/images/marina_logo.png', height: 26),
          const SizedBox(width: 10),
          Text('Pedestal ${p.codigo}'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _pedestal;

    return Scaffold(
      appBar: _appBar(p),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Barco: ${p.barco.isNotEmpty ? p.barco : 'N/D'}'),
            const SizedBox(height: 6),
            Text('Muelle: ${p.muelle?.toString() ?? 'N/D'}'),
            const Divider(height: 24),

            // =================== FILTROS ===================
            const Text('Filtros', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                // Filtro por técnico
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _tecnicoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Buscar por técnico',
                      hintText: 'Email o parte del email',
                      prefixIcon: Icon(Icons.person_search),
                    ),
                    onChanged: (_) => _aplicarFiltros(),
                  ),
                ),
                const SizedBox(width: 12),

                // Filtro por fecha
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: _pickFecha,
                    icon: const Icon(Icons.event),
                    label: Text(
                      _fechaFiltro == null
                          ? 'Filtrar por fecha'
                          : 'Fecha: ${_fechaFiltro!.year}-${_fechaFiltro!.month.toString().padLeft(2, '0')}-${_fechaFiltro!.day.toString().padLeft(2, '0')}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Limpiar
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _limpiarFiltros,
                    child: const Text('Limpiar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_fechaFiltro != null)
                  Chip(
                    label: Text(
                      'Fecha: ${_fechaFiltro!.year}-${_fechaFiltro!.month.toString().padLeft(2, '0')}-${_fechaFiltro!.day.toString().padLeft(2, '0')}',
                    ),
                    onDeleted: () {
                      setState(() => _fechaFiltro = null);
                      _aplicarFiltros();
                    },
                  ),
                if (_tecnicoCtrl.text.isNotEmpty)
                  Chip(
                    label: Text('Téc.: ${_tecnicoCtrl.text}'),
                    onDeleted: () {
                      _tecnicoCtrl.clear();
                      _aplicarFiltros();
                    },
                  ),
              ],
            ),
            const Divider(height: 24),

            // =================== HISTORIAL ===================
            Row(
              children: [
                const Text('Historial de mantenimientos',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Chip(label: Text('${_historial.length}')),
              ],
            ),
            const SizedBox(height: 8),

            // Campo de filtro por barco
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _barcoCtrl,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.directions_boat),
                  hintText: 'Filtrar mantenimientos por barco',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
                onChanged: (v) {
                  setState(() {
                    _filtroBarco = v.trim().toLowerCase();
                  });
                  _aplicarFiltros();
                },
              ),
            ),

            Expanded(
              child: _historial.isEmpty
                  ? const Center(child: Text('No hay registros con esos filtros'))
                  : ListView.builder(
                      itemCount: _historial.length,
                      itemBuilder: (_, i) {
                        final m = _historial[i];
                        // Determinar información de la pieza asociada al mantenimiento
                        final piezasDelPedestal = MockDataService().piezasDePedestal(p.id);
                        String piezaInfo = '';
                        if (m.piezaNombre != null && m.piezaNombre!.isNotEmpty) {
                          piezaInfo = m.piezaNombre!;
                        } else if (m.piezaId != null) {
                          final idx = piezasDelPedestal.indexWhere((pz) => pz.id == m.piezaId);
                          if (idx != -1) piezaInfo = piezasDelPedestal[idx].nombre;
                        }
                        return Card(
                          child: ListTile(
                            title: Text('${tipoToText(m.tipo)} — ${_fmt(m.fecha)}'),
                            subtitle: Text(
                              '${m.detalle}\nTécnico: ${m.tecnicoEmail}' +
                                  (piezaInfo.isNotEmpty ? '\nPieza: $piezaInfo' : '') +
                                  '\nBarco: ${m.barco.isNotEmpty ? m.barco : p.barco}',
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nuevo mantenimiento'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PantallaNuevoMantenimiento(pedestal: p),
            ),
          );
          _cargar(); // recarga y respeta filtros
        },
      ),
    );
  }
}
