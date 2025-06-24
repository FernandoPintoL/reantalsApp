import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers_providers/pago_provider.dart';
import '../../../controllers_providers/contrato_provider.dart';
import '../../../models/pago_model.dart';
import '../../../models/contrato_model.dart';
import '../../components/Loading.dart';

class HistorialPagosScreen extends StatefulWidget {
  const HistorialPagosScreen({Key? key}) : super(key: key);

  @override
  State<HistorialPagosScreen> createState() => _HistorialPagosScreenState();
}

class _HistorialPagosScreenState extends State<HistorialPagosScreen> {
  /*bool _isLoading = true;
  List<ContratoModel> _contratos = [];
  List<PagoModel> _pagosCompletados = [];*/

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await context.read<ContratoProvider>().loadContratosByClienteId();
    /*setState(() {
      _isLoading = true;
    });

    try {
      // Cargar todos los contratos del usuario (activos e históricos)
      await context.read<ContratoProvider>().loadContratosByClienteId();
      _contratos = context.read<ContratoProvider>().contratos;
      
      // Cargar pagos para cada contrato
      _pagosCompletados = [];
      for (var contrato in _contratos) {
        await context.read<PagoProvider>().loadPagosByContratoId(contrato.id);
        final pagos = context.read<PagoProvider>().pagos;
        
        // Filtrar solo pagos completados
        final completados = pagos.where((p) => p.estado == 'completado').toList();
        _pagosCompletados.addAll(completados);
      }
      
      // Ordenar pagos por fecha (más reciente primero)
      _pagosCompletados.sort((a, b) => b.fechaPago.compareTo(a.fechaPago));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los datos: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }*/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Pagos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: context.watch<PagoProvider>().isLoading
          ? Loading(title: 'Cargando historial de pagos...')
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (context.watch<PagoProvider>().pagosCompletadosCliente.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay historial de pagos',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: context.watch<PagoProvider>().pagosCompletadosCliente.length,
      itemBuilder: (context, index) {
        final pago = context.watch<PagoProvider>().pagosCompletadosCliente[index];
        // Encontrar el contrato asociado a este pago
        final contrato = context.watch<ContratoProvider>().contratos.firstWhere(
          (c) => c.id == pago.contratoId,
          orElse: () => ContratoModel(
            fechaInicio: DateTime.now(),
            fechaFin: DateTime.now(),
          ),
        );

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pago #${pago.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Chip(
                      label: const Text('Completado'),
                      backgroundColor: Colors.green.shade100,
                      labelStyle: TextStyle(color: Colors.green.shade800),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Contrato: ${contrato.inmueble?.nombre ?? "Propiedad"}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fecha de pago: ${_formatDate(pago.fechaPago)}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Monto: \$${pago.monto.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (pago.blockChainId != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.link, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'ID Blockchain: ${pago.blockChainId}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (pago.historialAcciones != null && pago.historialAcciones!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Historial de acciones:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...pago.historialAcciones!.map((accion) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text(
                      '• ${accion['accion']} - ${accion['fecha'] ?? 'Fecha no disponible'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  )).toList(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}