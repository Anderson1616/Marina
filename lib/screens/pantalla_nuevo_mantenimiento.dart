import 'package:flutter/material.dart';
import '../models/pedestal.dart';
import '../models/mantenimiento.dart';
import '../models/pieza.dart';
import '../services/mock_data_service.dart';

class PantallaNuevoMantenimiento extends StatefulWidget {
  final Pedestal pedestal;
  const PantallaNuevoMantenimiento({super.key, required this.pedestal});

  @override
  State<PantallaNuevoMantenimiento> createState() => _PantallaNuevoMantenimientoState();
}

class _PantallaNuevoMantenimientoState extends State<PantallaNuevoMantenimiento> {
  final _svc = MockDataService();
  final _detalle = TextEditingController();
  TipoIntervencion _tipo = TipoIntervencion.cambio;
  DateTime _fecha = DateTime.now();
  List<Pieza> _piezas = [];
  String? _selectedPiezaId;
  final _nombrePiezaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _piezas = MockDataService().piezasDePedestal(widget.pedestal.id);
  }

  Future<void> _guardar() async {
    if (_detalle.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el detalle del trabajo')),
      );
      return;
    }
    // No crear objeto Mantenimiento local, se usa el servicio para crear y sincronizar
    // luego llamar al servicio para agregarlo
    await _svc.agregarMantenimiento(
      pedestalId: widget.pedestal.id,
      tipo: _tipo,
      detalle: _detalle.text.trim(),
      fecha: _fecha,
      barco: widget.pedestal.barco,
      piezaId: _selectedPiezaId,
      piezaNombre: _nombrePiezaCtrl.text.isNotEmpty ? _nombrePiezaCtrl.text : null,
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _fecha,
    );
    if (picked != null) {
      setState(() {
        _fecha = DateTime(picked.year, picked.month, picked.day, _fecha.hour, _fecha.minute);
      });
    }
  }

  @override
  void dispose() {
    _nombrePiezaCtrl.dispose();
    _detalle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pedestal;
    return Scaffold(
      appBar: AppBar(title: Text('Nuevo mantenimiento – ${p.codigo}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('Fecha: ${_fecha.toLocal().toString().split(' ').first}')),
                TextButton(onPressed: _pickFecha, child: const Text('Cambiar fecha')),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<TipoIntervencion>(
              // 👇 usar initialValue (no value)
              initialValue: _tipo,
              decoration: const InputDecoration(
                labelText: 'Tipo de intervención',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: TipoIntervencion.adicion, child: Text('Adición')),
                DropdownMenuItem(value: TipoIntervencion.eliminacion, child: Text('Eliminación')),
                DropdownMenuItem(value: TipoIntervencion.cambio, child: Text('Cambio')),
              ],
              onChanged: (v) => setState(() => _tipo = v ?? TipoIntervencion.cambio),
            ),
            const SizedBox(height: 12),
            if (_tipo == TipoIntervencion.adicion) ...[
              TextField(controller: _nombrePiezaCtrl, decoration: const InputDecoration(labelText: 'Nombre de pieza (nueva)')),
            ],
            if (_tipo == TipoIntervencion.eliminacion || _tipo == TipoIntervencion.cambio) ...[
              DropdownButtonFormField<String?>(
                value: _selectedPiezaId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Seleccionar pieza (opcional)')),
                  ..._piezas.map((pz) => DropdownMenuItem(value: pz.id, child: Text(pz.nombre))).toList(),
                ],
                onChanged: (v) => setState(() => _selectedPiezaId = v),
                decoration: const InputDecoration(labelText: 'Pieza existente'),
              ),
              if (_tipo == TipoIntervencion.cambio)
                TextField(controller: _nombrePiezaCtrl, decoration: const InputDecoration(labelText: 'Nuevo nombre de pieza')),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _detalle,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Detalle del trabajo',
                hintText: 'Ej.: Se cambió la toma 240V y el breaker de 50A',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _guardar,
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
// Verificar que no existe etiqueta 'Ubicación' en esta pantalla; no se requieren cambios.
