import 'package:flutter/material.dart';
import '../models/pedestal.dart';
import '../models/mantenimiento.dart';
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

  // Datos
  List<Mantenimiento> _historialBase = [];
  List<Mantenimiento> _historial = [];

  // Filtros
  final _tecnicoCtrl = TextEditingController();
  DateTime? _fechaFiltro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _historialBase = _svc.mantenimientosPorPedestal(widget.pedestal.id);
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    final t = _tecnicoCtrl.text.trim().toLowerCase();
    final f = _fechaFiltro;

    final res = _historialBase.where((m) {
      bool okTecnico = true;
      bool okFecha = true;

      if (t.isNotEmpty) {
        okTecnico = m.tecnicoEmail.toLowerCase().contains(t);
      }

      if (f != null) {
        okFecha = m.fecha.year == f.year &&
            m.fecha.month == f.month &&
            m.fecha.day == f.day;
      }

      return okTecnico && okFecha;
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
    setState(() => _fechaFiltro = null);
    _aplicarFiltros();
  }

  String _fmt(DateTime f) =>
      '${f.year}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')} '
      '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final p = widget.pedestal;

    return Scaffold(
      appBar: AppBar(title: Text('Pedestal ${p.codigo}')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ubicación: ${p.ubicacion ?? 'N/D'}'),
            const SizedBox(height: 6),
            Text('Muelle: ${p.muelle ?? 'N/D'}'),
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
                      border: OutlineInputBorder(),
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
            const Divider(height: 24),

            // =================== HISTORIAL ===================
            const Text('Historial de mantenimientos',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: _historial.isEmpty
                  ? const Center(child: Text('No hay registros con esos filtros'))
                  : ListView.builder(
                      itemCount: _historial.length,
                      itemBuilder: (_, i) {
                        final m = _historial[i];
                        return Card(
                          child: ListTile(
                            title: Text('${tipoToText(m.tipo)} — ${_fmt(m.fecha)}'),
                            subtitle: Text('${m.detalle}\nTécnico: ${m.tecnicoEmail}'),
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
