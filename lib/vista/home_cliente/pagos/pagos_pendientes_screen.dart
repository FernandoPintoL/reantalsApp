import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentals/vista/components/Loading.dart';
import '../../../controllers_providers/pago_provider.dart';
import '../../../controllers_providers/contrato_provider.dart';
import '../../../models/pago_model.dart';
import '../../../models/contrato_model.dart';
import 'realizar_pago_screen.dart';

class PagosPendientesScreen extends StatefulWidget {
  const PagosPendientesScreen({Key? key}) : super(key: key);

  @override
  State<PagosPendientesScreen> createState() => _PagosPendientesScreenState();
}

class _PagosPendientesScreenState extends State<PagosPendientesScreen> {
  // bool _isLoading = true;
  List<ContratoModel> _contratosActivos = [];
  // List<PagoModel> _pagosPendientes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() async {
    await context.read<PagoProvider>().loadPagosPendientesCliente();
    /*try {
      // Cargar contratos activos del usuario
      await context.read<ContratoProvider>().loadContratosByClienteId();
      final contratos = context.read<ContratoProvider>().contratos;

      // Filtrar solo contratos activos
      _contratosActivos = contratos.where((c) => c.estado == 'activo').toList();

      // Cargar pagos pendientes para cada contrato
      _pagosPendientes = [];
      for (var contrato in _contratosActivos) {
        await context.read<PagoProvider>().loadPagosByContratoId(contrato.id);
        final pagos = context.read<PagoProvider>().pagos;

        // Filtrar solo pagos pendientes
        final pendientes = pagos.where((p) => p.estado == 'pendiente').toList();
        _pagosPendientes.addAll(pendientes);
      }
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
        title: Text('Pagos Pendientes ${context.watch<PagoProvider>().currentUser?.name ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: context.watch<PagoProvider>().isLoading
          ? Loading(title: 'Cargando pagos pendientes...')
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (context.watch<PagoProvider>().pagosPendientesCliente.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'No tienes pagos pendientes',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: context.watch<PagoProvider>().pagosPendientesCliente.length,
      itemBuilder: (context, index) {
        final pago = context.watch<PagoProvider>().pagosPendientesCliente[index];
        // Encontrar el contrato asociado a este pago
        final contrato = _contratosActivos.firstWhere(
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
                      label: const Text('Pendiente'),
                      backgroundColor: Colors.orange.shade100,
                      labelStyle: TextStyle(color: Colors.orange.shade800),
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _realizarPago(pago, contrato),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Realizar Pago'),
                  ),
                ),
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

  void _realizarPago(PagoModel pago, ContratoModel contrato) {
    // Navegar a la pantalla de realizar pago con los datos del pago seleccionado
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RealizarPagoScreen(
          pago: pago,
          contrato: contrato,
        ),
      ),
    );
  }
}
