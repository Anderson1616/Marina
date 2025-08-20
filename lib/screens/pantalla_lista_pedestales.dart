import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/mock_data_service.dart';
import '../models/pedestal.dart';
import 'pantalla_detalle_pedestal.dart';
import 'pantalla_login.dart';
import 'pantalla_editar_pedestal.dart';
import 'pantalla_piezas_pedestal.dart';
import 'pantalla_nuevo_pedestal.dart';

class PantallaListaPedestales extends StatefulWidget {
  const PantallaListaPedestales({super.key});

  @override
  State<PantallaListaPedestales> createState() => _PantallaListaPedestalesState();
}

class _PantallaListaPedestalesState extends State<PantallaListaPedestales> {
  final mockDataService = MockDataService();
  List<Pedestal> pedestales = [];
  final _buscar = TextEditingController();

  @override
  void initState() {
    super.initState();
    pedestales = mockDataService.listarPedestales();
    mockDataService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    mockDataService.removeListener(_onDataChanged);
    _buscar.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    setState(() {
      pedestales = mockDataService.listarPedestales();
    });
  }

  void _cargar() {
    setState(() {
      pedestales = mockDataService.listarPedestales(filtro: _buscar.text);
    });
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
      await mockDataService.eliminarPedestal(p.id);
      // _cargar();
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
            child: pedestales.isEmpty
                ? const Center(child: Text('Sin pedestales'))
                : ListView.builder(
                    itemCount: pedestales.length,
                    itemBuilder: (_, i) {
                      final p = pedestales[i];
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
                            subtitle: Text(p.barco),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // botón eliminar existente
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Eliminar',
                                  onPressed: () => _confirmarEliminar(p),
                                  color: cs.error,
                                ),
                                // nuevo botón editar
                                IconButton(
                                  icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                                  tooltip: 'Editar pedestal',
                                  onPressed: () async {
                                    // Navegar a la pantalla de edición
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PantallaEditarPedestal(pedestal: p),
                                      ),
                                    );
                                  },
                                ),
                                // nuevo botón ver piezas
                                IconButton(
                                  icon: Icon(Icons.remove_red_eye_outlined, color: Theme.of(context).primaryColor),
                                  tooltip: 'Ver piezas',
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaPiezasPedestal(pedestal: p)));
                                  },
                                ),
                              ],
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
        icon: const Icon(Icons.add),
        label: const Text('Añadir'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PantallaNuevoPedestal()),
          );
          // la lista se actualizará automáticamente por el listener del servicio
        },
      ),
    );
  }
}
