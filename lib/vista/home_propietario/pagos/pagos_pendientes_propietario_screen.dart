import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentals/vista/components/Loading.dart';
import '../../../controllers_providers/pago_provider.dart';
import '../../../controllers_providers/contrato_provider.dart';
import '../../../models/pago_model.dart';
import '../../../models/contrato_model.dart';

class PagosPendientesPropietarioScreen extends StatefulWidget {
  const PagosPendientesPropietarioScreen({Key? key}) : super(key: key);

  @override
  State<PagosPendientesPropietarioScreen> createState() => _PagosPendientesPropietarioScreenState();
}

class _PagosPendientesPropietarioScreenState extends State<PagosPendientesPropietarioScreen> {
  List<ContratoModel> _contratosActivos = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() async {
    // Cargar pagos pendientes del propietario
    await context.read<PagoProvider>().loadPagosPendientesPropietario();
    
    // Cargar contratos para obtener información adicional
    await context.read<ContratoProvider>().loadContratosByPropietarioId();
    setState(() {
      _contratosActivos = context.read<ContratoProvider>().contratos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pagos Pendientes de Recibir'),
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
    if (context.watch<PagoProvider>().pagosPendientesPropietario.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'No tienes pagos pendientes de recibir',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: context.watch<PagoProvider>().pagosPendientesPropietario.length,
      itemBuilder: (context, index) {
        final pago = context.watch<PagoProvider>().pagosPendientesPropietario[index];
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
                  'Propiedad: ${contrato.inmueble?.nombre ?? "Propiedad"}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cliente: ${contrato.cliente?.name ?? "Cliente"}',
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
                if (pago.descripcion != null && pago.descripcion!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Descripción: ${pago.descripcion}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _enviarRecordatorio(pago, contrato),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Enviar Recordatorio'),
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

  void _enviarRecordatorio(PagoModel pago, ContratoModel contrato) {
    // Mostrar un mensaje de éxito (en una implementación real, esto enviaría un recordatorio)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recordatorio enviado a ${contrato.cliente?.name ?? "cliente"} para el pago #${pago.id}'),
        backgroundColor: Colors.green,
      ),
    );
  }
}