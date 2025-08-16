import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/mock_data_service.dart';
import '../models/pedestal.dart';
import 'pantalla_detalle_pedestal.dart';
import 'pantalla_login.dart';

class PantallaListaPedestales extends StatefulWidget {
  const PantallaListaPedestales({super.key});

  @override
  State<PantallaListaPedestales> createState() => _PantallaListaPedestalesState();
}

class _PantallaListaPedestalesState extends State<PantallaListaPedestales> {
  final _svc = MockDataService();
  final _buscar = TextEditingController();
  List<Pedestal> _data = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() => _data = _svc.listarPedestales(filtro: _buscar.text));
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const PantallaLogin()),
      (_) => false,
    );
  }

  // --------- NUEVO: diálogo "Añadir pedestal" ----------
  Future<void> _mostrarDialogoNuevoPedestal() async {
    final codigoCtrl = TextEditingController();
    final muelleCtrl = TextEditingController();
    final ubicCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo pedestal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codigoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Código (ej. N-6)',
                  hintText: 'Formato sugerido: LETRA-NÚMERO',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: muelleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Muelle (opcional)',
                  hintText: 'N / S / Este / Oeste',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ubicCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ubicación (opcional)',
                  hintText: 'Ej. Muelle Norte 6',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _svc.crearPedestal(
        codigo: codigoCtrl.text,
        muelle: muelleCtrl.text,
        ubicacion: ubicCtrl.text,
      );
      _cargar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedestal creado')),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  // --------- NUEVO: confirmación de eliminación ----------
  Future<void> _confirmarEliminar(Pedestal p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar pedestal'),
        content: Text(
          '¿Seguro que deseas eliminar el pedestal ${p.codigo}? '
          'Se borrará también su historial (mock).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _svc.eliminarPedestal(p.id);
      _cargar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eliminado ${p.codigo}')),
      );
    }
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          Image.asset('assets/images/marina_logo.png', height: 26),
          const SizedBox(width: 10),
          const Text('Pedestales'),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Cerrar sesión',
          onPressed: _logout,
          icon: const Icon(Icons.logout),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _appBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _buscar,
              decoration: const InputDecoration(
                labelText: 'Buscar por código (ej. N-6)',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => _cargar(),
            ),
          ),
          Expanded(
            child: _data.isEmpty
                ? const Center(child: Text('Sin pedestales'))
                : ListView.builder(
                    itemCount: _data.length,
                    itemBuilder: (_, i) {
                      final p = _data[i];
                      return Dismissible(
                        key: ValueKey(p.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                        // 👇 reemplazo de withOpacity por withValues
                        color: Colors.red.withValues(alpha: 0.15),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Icon(Icons.delete, color: Colors.red),
                        ),

                        confirmDismiss: (_) async {
                          await _confirmarEliminar(p);
                          // Evitamos que Dismissible quite el item automáticamente
                          return false;
                        },
                        child: Card(
                          child: ListTile(
                            title: Text(
                              p.codigo,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(p.ubicacion ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Eliminar',
                              onPressed: () => _confirmarEliminar(p),
                              color: cs.error,
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PantallaDetallePedestal(pedestal: p),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNuevoPedestal,
        icon: const Icon(Icons.add),
        label: const Text('Añadir'),
      ),
    );
  }
}
