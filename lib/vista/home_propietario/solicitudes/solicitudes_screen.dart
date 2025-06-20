import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/solicitud_alquiler_model.dart';
import '../../../providers/solicitud_alquiler_provider.dart';
import 'crear_contrato_screen.dart';

class SolicitudesScreen extends StatefulWidget {
  const SolicitudesScreen({Key? key}) : super(key: key);

  @override
  State<SolicitudesScreen> createState() => _SolicitudesScreenState();
}

class _SolicitudesScreenState extends State<SolicitudesScreen> {
  @override
  void initState() {
    super.initState();
    // Load rental requests for the current property owner
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SolicitudAlquilerProvider>().loadSolicitudesByPropietarioId();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes de Alquiler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SolicitudAlquilerProvider>().loadSolicitudesByPropietarioId();
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Consumer<SolicitudAlquilerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.message != null && provider.solicitudes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.loadSolicitudesByPropietarioId();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (provider.solicitudes.isEmpty) {
            return const Center(
              child: Text(
                'No hay solicitudes de alquiler pendientes',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.solicitudes.length,
            itemBuilder: (context, index) {
              final solicitud = provider.solicitudes[index];
              return _buildSolicitudCard(context, solicitud, provider);
            },
          );
        },
      ),
    );
  }

  Widget _buildSolicitudCard(
      BuildContext context, SolicitudAlquilerModel solicitud, SolicitudAlquilerProvider provider) {
    // Get status color
    Color statusColor;
    switch (solicitud.estado.toLowerCase()) {
      case 'pendiente':
        statusColor = Colors.orange;
        break;
      case 'contrato_generado':
        statusColor = Colors.blue;
        break;
      case 'rechazada':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with property name and status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    solicitud.inmueble?.nombre ?? 'Inmueble sin nombre',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(solicitud.estado),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Client info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cliente: ${solicitud.cliente?.name ?? "Cliente desconocido"}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Email: ${solicitud.cliente?.email ?? ""}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Teléfono: ${solicitud.cliente?.telefono ?? ""}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                
                // Requested services
                const Text(
                  'Servicios Solicitados:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: solicitud.serviciosBasicos.map((servicio) {
                    return Chip(
                      label: Text(servicio.nombre),
                      backgroundColor: Colors.blue.shade100,
                    );
                  }).toList(),
                ),
                
                // Additional message
                if (solicitud.mensaje != null && solicitud.mensaje!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Mensaje Adicional:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      solicitud.mensaje!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (solicitud.estado.toLowerCase() == 'pendiente') ...[
                      TextButton.icon(
                        onPressed: () {
                          _showRejectConfirmationDialog(context, solicitud, provider);
                        },
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: const Text(
                          'Rechazar',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to contract creation screen
                          provider.selectSolicitud(solicitud);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CrearContratoScreen(
                                solicitud: solicitud,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.description),
                        label: const Text('Crear Contrato'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ] else if (solicitud.estado.toLowerCase() == 'contrato_generado') ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to contract details screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Funcionalidad en desarrollo: Ver Contrato'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('Ver Contrato'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'contrato_generado':
        return 'Contrato Generado';
      case 'rechazada':
        return 'Rechazada';
      default:
        return status;
    }
  }

  void _showRejectConfirmationDialog(
      BuildContext context, SolicitudAlquilerModel solicitud, SolicitudAlquilerProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar rechazo'),
        content: Text(
            '¿Estás seguro de que deseas rechazar la solicitud de alquiler para "${solicitud.inmueble?.nombre ?? 'este inmueble'}"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.updateSolicitudEstado(solicitud.id, 'rechazada');
            },
            child: const Text(
              'Rechazar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}