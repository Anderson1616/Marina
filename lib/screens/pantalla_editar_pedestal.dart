import 'package:flutter/material.dart';
import '../models/pedestal.dart';
import '../services/mock_data_service.dart';

class PantallaEditarPedestal extends StatefulWidget {
  final Pedestal pedestal;
  PantallaEditarPedestal({required this.pedestal});

  @override
  _PantallaEditarPedestalState createState() => _PantallaEditarPedestalState();
}

class _PantallaEditarPedestalState extends State<PantallaEditarPedestal> {
  late TextEditingController _codigoCtrl;
  late TextEditingController _muelleCtrl;
  late TextEditingController _barcoCtrl;

  @override
  void initState() {
    super.initState();
    _codigoCtrl = TextEditingController(text: widget.pedestal.codigo);
    _muelleCtrl = TextEditingController(text: widget.pedestal.muelle?.toString() ?? '');
    _barcoCtrl = TextEditingController(text: widget.pedestal.barco);
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _muelleCtrl.dispose();
    _barcoCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    final updated = Pedestal(
      id: widget.pedestal.id,
      codigo: _codigoCtrl.text,
      muelle: int.tryParse(_muelleCtrl.text) ?? widget.pedestal.muelle,
      barco: _barcoCtrl.text,
    );
    // Actualizar en el servicio mock centralizado para que otras pantallas vean el cambio
    MockDataService().updatePedestal(updated);
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
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
            TextField(controller: _barcoCtrl, decoration: InputDecoration(labelText: 'Barco (nombre o ID)')),
            SizedBox(height: 20),
            ElevatedButton.icon(onPressed: _guardar, icon: Icon(Icons.save), label: Text('Guardar')),
          ],
        ),
      ),
    );
  }
}
