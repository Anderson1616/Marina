import 'package:flutter/material.dart';
import '../services/mock_data_service.dart';
import '../models/pieza.dart';

class PantallaNuevoPedestal extends StatefulWidget {
  const PantallaNuevoPedestal({Key? key}) : super(key: key);

  @override
  State<PantallaNuevoPedestal> createState() => _PantallaNuevoPedestalState();
}

class _PantallaNuevoPedestalState extends State<PantallaNuevoPedestal> {
  final _codigoCtrl = TextEditingController();
  final _muelleCtrl = TextEditingController();
  final _barcoCtrl = TextEditingController();

  final _piezaCtrl = TextEditingController();
  final List<Pieza> _piezasTemporales = [];

  final MockDataService _svc = MockDataService();
  bool _guardando = false;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _muelleCtrl.dispose();
    _barcoCtrl.dispose();
    _piezaCtrl.dispose();
    super.dispose();
  }

  void _agregarPiezaLocal() {
    final nombre = _piezaCtrl.text.trim();
    if (nombre.isEmpty) return;
    if (_piezasTemporales.any((p) => p.nombre.toLowerCase() == nombre.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ya existe una pieza con ese nombre')));
      return;
    }
    final pieza = Pieza(id: DateTime.now().microsecondsSinceEpoch.toString(), nombre: nombre, creadaEn: DateTime.now());
    setState(() {
      _piezasTemporales.add(pieza);
      _piezaCtrl.clear();
    });
  }

  Future<void> _guardar() async {
    final codigo = _codigoCtrl.text.trim();
    if (codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El código es obligatorio')));
      return;
    }
    setState(() => _guardando = true);
    try {
      final nuevo = await _svc.crearPedestal(codigo: codigo, muelle: _muelleCtrl.text.trim(), barco: _barcoCtrl.text.trim());
      // agregar piezas temporales y registrar mantenimiento por cada una
      for (final p in _piezasTemporales) {
        await _svc.agregarPieza(pedestalId: nuevo.id, nombre: p.nombre, registrarMantenimiento: true);
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedestal creado')));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _guardando = false);
    }
  }

  void _editarPiezaLocal(int index) async {
    final current = _piezasTemporales[index];
    final ctrl = TextEditingController(text: current.nombre);
    final nuevo = await showDialog<String?>(context: context, builder: (_) {
      return AlertDialog(
        title: const Text('Editar pieza'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Nombre')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(ctrl.text.trim()), child: const Text('Guardar')),
        ],
      );
    });
    if (nuevo != null && nuevo.isNotEmpty) {
      setState(() => _piezasTemporales[index].nombre = nuevo);
    }
  }

  void _eliminarPiezaLocal(int index) {
    setState(() => _piezasTemporales.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo pedestal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _codigoCtrl, decoration: const InputDecoration(labelText: 'Código')),
            const SizedBox(height: 8),
            TextField(controller: _muelleCtrl, decoration: const InputDecoration(labelText: 'Muelle')),
            const SizedBox(height: 8),
            TextField(controller: _barcoCtrl, decoration: const InputDecoration(labelText: 'Barco (opcional)')),
            const SizedBox(height: 16),
            const Text('Piezas iniciales', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: _piezaCtrl, decoration: const InputDecoration(hintText: 'Nombre de pieza'))),
              IconButton(onPressed: _agregarPiezaLocal, icon: const Icon(Icons.add)),
            ]),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _piezasTemporales.length,
                itemBuilder: (_, i) {
                  final p = _piezasTemporales[i];
                  return ListTile(
                    title: Text(p.nombre),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () => _editarPiezaLocal(i)),
                      IconButton(icon: const Icon(Icons.delete), onPressed: () => _eliminarPiezaLocal(i)),
                    ]),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ElevatedButton(onPressed: _guardando ? null : _guardar, child: const Text('Guardar'))),
            ])
          ],
        ),
      ),
    );
  }
}
