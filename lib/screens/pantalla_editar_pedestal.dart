import 'package:flutter/material.dart';
import '../models/pedestal.dart';
import '../services/mock_data_service.dart';
import '../models/pieza.dart';

class PantallaEditarPedestal extends StatefulWidget {
  final Pedestal pedestal;
  const PantallaEditarPedestal({Key? key, required this.pedestal}) : super(key: key);

  @override
  _PantallaEditarPedestalState createState() => _PantallaEditarPedestalState();
}

class _PantallaEditarPedestalState extends State<PantallaEditarPedestal> {
  List<Pieza> _piezas = [];
  late Pedestal _pedestal;

  late TextEditingController _codigoCtrl;
  late TextEditingController _muelleCtrl;
  late TextEditingController _barcoCtrl;

  @override
  void initState() {
    super.initState();
    final maybe = MockDataService().getPedestalById(widget.pedestal.id);
    _pedestal = maybe ?? widget.pedestal;
    _codigoCtrl = TextEditingController(text: _pedestal.codigo);
    _muelleCtrl = TextEditingController(text: _pedestal.muelle?.toString() ?? '');
    _barcoCtrl = TextEditingController(text: _pedestal.barco);
    _loadPiezas();
  }

  void _loadPiezas() {
    _piezas = MockDataService().piezasDePedestal(_pedestal.id);
  }

  void _eliminarPieza(Pieza pieza) async {
    try {
      await MockDataService().eliminarPieza(pedestalId: widget.pedestal.id, piezaId: pieza.id, registrarMantenimiento: true, tecnicoEmailOverride: null);
      _loadPiezas();
      if (!mounted) return;
      setState(() {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pieza eliminada')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _editarPieza(Pieza pieza) async {
    final ctrl = TextEditingController(text: pieza.nombre);
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
      try {
        await MockDataService().editarPieza(pedestalId: widget.pedestal.id, piezaId: pieza.id, nuevoNombre: nuevo, registrarMantenimiento: true);
        _loadPiezas();
        if (!mounted) return;
        setState(() {});
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pieza actualizada')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _guardar() {
    final updated = _pedestal.copyWith(
      codigo: _codigoCtrl.text,
      muelle: _muelleCtrl.text.trim().isEmpty ? null : _muelleCtrl.text.trim(),
      barco: _barcoCtrl.text,
    );
    // Actualizar en el servicio mock centralizado para que otras pantallas vean el cambio
    MockDataService().updatePedestal(updated);
    // actualizar estado local antes de cerrar
    setState(() {
      _pedestal = updated;
    });
    Navigator.of(context).pop(updated);
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _muelleCtrl.dispose();
    _barcoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Asegurar que el controlador de muelle refleje el valor actual del pedestal
    if (_muelleCtrl.text.isEmpty && _pedestal.muelle != null) {
      _muelleCtrl.text = _pedestal.muelle.toString();
    }
    return Scaffold(
      appBar: AppBar(title: Text('Editar pedestal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _codigoCtrl, decoration: InputDecoration(labelText: 'Código')),
            SizedBox(height: 12),
            TextField(controller: _muelleCtrl, decoration: InputDecoration(labelText: 'Muelle'), keyboardType: TextInputType.number),
            SizedBox(height: 12),
            TextField(controller: _barcoCtrl, decoration: InputDecoration(labelText: 'Barco (opcional)')),
            SizedBox(height: 20),
            ElevatedButton.icon(onPressed: _guardar, icon: Icon(Icons.save), label: Text('Guardar')),
            const SizedBox(height: 12),
            Text('Piezas', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._piezas.map((pz) => ListTile(
              title: Text(pz.nombre),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: Icon(Icons.edit), onPressed: () => _editarPieza(pz)),
                IconButton(icon: Icon(Icons.delete), onPressed: () => _eliminarPieza(pz)),
              ]),
            )).toList(),
          ],
        ),
      ),
    );
  }
}
