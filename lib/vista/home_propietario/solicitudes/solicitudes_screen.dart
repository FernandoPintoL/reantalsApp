import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/solicitud_alquiler_model.dart';
import '../../../controllers_providers/solicitud_alquiler_provider.dart';
import 'crear_contrato_screen.dart';

class SolicitudesScreen extends StatefulWidget {
  const SolicitudesScreen({Key? key}) : super(key: key);

  @override
  State<SolicitudesScreen> createState() => _SolicitudesScreenState();
}

class _SolicitudesScreenState extends State<SolicitudesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'todos'; // Default to show all statuses

  // List of available status types
  final List<Map<String, dynamic>> _statusTypes = [
    {'value': 'todos', 'label': 'Todos', 'icon': Icons.list_alt},
    {'value': 'pendiente', 'label': 'Pendientes', 'icon': Icons.pending_actions},
    {'value': 'aprobada', 'label': 'Aprobadas', 'icon': Icons.check_circle},
    {'value': 'rechazada', 'label': 'Rechazadas', 'icon': Icons.cancel},
    {'value': 'anulada', 'label': 'Anuladas', 'icon': Icons.block},
    {'value': 'contrato_generado', 'label': 'Con Contrato', 'icon': Icons.description},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTypes.length, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Load rental requests for the current property owner
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SolicitudAlquilerProvider>().loadSolicitudesByPropietarioId();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedStatus = _statusTypes[_tabController.index]['value'];
      });
    }
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _statusTypes.map((status) {
            return Tab(
              icon: Icon(status['icon'] as IconData),
              text: status['label'] as String,
            );
          }).toList(),
        ),
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

          // Filter solicitudes based on selected status
          final filteredSolicitudes = _selectedStatus == 'todos'
              ? provider.solicitudes
              : provider.solicitudes.where((solicitud) => solicitud.estado == _selectedStatus).toList();

          if (filteredSolicitudes.isEmpty) {
            return Center(
              child: Text(
                'No hay solicitudes de alquiler ${_getStatusLabel(_selectedStatus).toLowerCase()}',
                style: const TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredSolicitudes.length,
            itemBuilder: (context, index) {
              final solicitud = filteredSolicitudes[index];
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
    Color statusColor = _getStatusColor(solicitud.estado);

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
                    _getStatusLabel(solicitud.estado),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Property info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Información del Inmueble:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Detalle: ${solicitud.inmueble?.detalle ?? "No disponible"}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Precio: \$${solicitud.inmueble?.precio?.toStringAsFixed(2) ?? "No disponible"}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          // Client info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Información del Cliente:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nombre: ${solicitud.cliente?.name ?? "Cliente desconocido"}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Email: ${solicitud.cliente?.email ?? "No disponible"}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Teléfono: ${solicitud.cliente?.telefono ?? "No disponible"}',
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
                  children: solicitud.servicios_basicos!.map((servicio) {
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
      case 'aprobada':
        return 'Aprobada';
      case 'anulada':
        return 'Anulada';
      default:
        return status;
    }
  }

  String _getStatusLabel(String status) {
    final statusMap = _statusTypes.firstWhere(
      (element) => element['value'] == status,
      orElse: () => {'label': 'Desconocido'},
    );
    return statusMap['label'] as String;
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
              await provider.updateSolicitudEstado(solicitud.id, 'rechazada', context: context);
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
