import 'package:flutter/material.dart';
import '../models/pedestal.dart';
import '../models/pieza.dart';
import '../services/mock_data_service.dart';

class PantallaPiezasPedestal extends StatefulWidget {
  final Pedestal pedestal;
  const PantallaPiezasPedestal({Key? key, required this.pedestal}) : super(key: key);

  @override
  State<PantallaPiezasPedestal> createState() => _PantallaPiezasPedestalState();
}

class _PantallaPiezasPedestalState extends State<PantallaPiezasPedestal> {
  final MockDataService _svc = MockDataService();
  late List<Pieza> piezas;

  @override
  void initState() {
    super.initState();
    piezas = _svc.piezasDePedestal(widget.pedestal.id);
    _svc.addListener(_onData);
  }

  @override
  void dispose() {
    _svc.removeListener(_onData);
    super.dispose();
  }

  void _onData() {
    setState(() {
      piezas = _svc.piezasDePedestal(widget.pedestal.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pedestal;
    return Scaffold(
      appBar: AppBar(title: Text('Piezas — ${p.codigo}')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: piezas.isEmpty
            ? const Center(child: Text('No hay piezas'))
            : ListView.builder(
                itemCount: piezas.length,
                itemBuilder: (_, i) {
                  final pieza = piezas[i];
                  return ListTile(
                    title: Text(pieza.nombre),
                    subtitle: Text('Creada: ${pieza.creadaEn.year}-${pieza.creadaEn.month.toString().padLeft(2,'0')}-${pieza.creadaEn.day.toString().padLeft(2,'0')} ${pieza.creadaEn.hour.toString().padLeft(2,'0')}:${pieza.creadaEn.minute.toString().padLeft(2,'0')}'),
                  );
                },
              ),
      ),
    );
  }
}
