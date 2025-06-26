import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers_providers/solicitud_alquiler_provider.dart';
import '../../../models/solicitud_alquiler_model.dart';
import '../../components/message_widget.dart';

class SolicitudesPendientesScreen extends StatefulWidget {
  const SolicitudesPendientesScreen({Key? key}) : super(key: key);

  @override
  _SolicitudesPendientesScreenState createState() => _SolicitudesPendientesScreenState();
}

class _SolicitudesPendientesScreenState extends State<SolicitudesPendientesScreen> {
  @override
  void initState() {
    super.initState();
    // Load solicitudes when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SolicitudAlquilerProvider>().loadSolicitudesByClienteId();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes de Alquiler Pendientes'),
      ),
      body: Consumer<SolicitudAlquilerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.message != null && provider.solicitudes.isEmpty) {
            return Center(
              child: MessageWidget(
                message: provider.message!,
                type: provider.messageType,
              ),
            );
          }

          // Filter solicitudes to only show pending ones
          final pendingSolicitudes = provider.solicitudes
              .where((solicitud) => solicitud.estado == 'pendiente')
              .toList();

          if (pendingSolicitudes.isEmpty) {
            return const Center(
              child: Text('No tienes solicitudes de alquiler pendientes'),
            );
          }

          return ListView.builder(
            itemCount: pendingSolicitudes.length,
            itemBuilder: (context, index) {
              final solicitud = pendingSolicitudes[index];
              return _buildSolicitudCard(context, solicitud);
            },
          );
        },
      ),
    );
  }

  Widget _buildSolicitudCard(BuildContext context, SolicitudAlquilerModel solicitud) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Inmueble information
            if (solicitud.inmueble != null) ...[
              Text(
                solicitud.inmueble!.nombre,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                solicitud.inmueble!.detalle ?? 'Sin detalles',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.hotel, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Habitaciones: ${solicitud.inmueble!.numHabitacion}',
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.stairs, size: 16),
                  const SizedBox(width: 4),
                  Text('Piso: ${solicitud.inmueble!.numPiso}'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Precio: \$${solicitud.inmueble!.precio.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else ...[
              Text(
                'Inmueble ID: ${solicitud.inmuebleId}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],

            const Divider(),

            // Solicitud information
            Text(
              'Estado: ${solicitud.estado}',
              style: TextStyle(
                color: _getStatusColor(solicitud.estado),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Servicios básicos
            if (solicitud.servicios_basicos != null && solicitud.servicios_basicos!.isNotEmpty) ...[
              Text(
                'Servicios solicitados:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: solicitud.servicios_basicos!.map((servicio) {
                  return Chip(
                    label: Text(servicio.nombre),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  );
                }).toList(),
              ),
            ],

            // Mensaje
            if (solicitud.mensaje != null && solicitud.mensaje!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Mensaje:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(solicitud.mensaje!),
            ],

            // Fecha
            const SizedBox(height: 8),
            Text(
              'Fecha de solicitud: ${_formatDate(solicitud.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            // Cancel button
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCancelConfirmationDialog(context, solicitud),
                icon: const Icon(Icons.cancel, color: Colors.white),
                label: const Text('Anular Solicitud'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'aprobada':
        return Colors.green;
      case 'rechazada':
        return Colors.red;
      case 'anulada':
        return Colors.grey;
      case 'contrato_generado':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Fecha desconocida';

    try {
      final DateTime date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  // Show confirmation dialog before canceling a rental request
  Future<void> _showCancelConfirmationDialog(BuildContext context, SolicitudAlquilerModel solicitud) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Anulación'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('¿Está seguro que desea anular esta solicitud de alquiler?'),
                SizedBox(height: 8),
                Text('Esta acción no se puede deshacer.', style: TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Anular Solicitud', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close the dialog

                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Anulando solicitud...'),
                    duration: Duration(seconds: 1),
                  ),
                );

                // Call the provider to update the status
                final provider = Provider.of<SolicitudAlquilerProvider>(context, listen: false);
                final success = await provider.updateSolicitudEstado(solicitud.id, 'anulada', context: context);

                // Show result message
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Solicitud anulada exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.message ?? 'Error al anular la solicitud'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
