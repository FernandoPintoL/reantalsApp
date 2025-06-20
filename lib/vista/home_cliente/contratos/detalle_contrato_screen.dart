import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/contrato_model.dart';
import '../../../providers/contrato_provider.dart';

class DetalleContratoScreen extends StatefulWidget {
  final ContratoModel contrato;

  const DetalleContratoScreen({
    Key? key,
    required this.contrato,
  }) : super(key: key);

  @override
  State<DetalleContratoScreen> createState() => _DetalleContratoScreenState();
}

class _DetalleContratoScreenState extends State<DetalleContratoScreen> {
  final dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Contrato'),
      ),
      body: Consumer<ContratoProvider>(
        builder: (context, provider, child) {
          final contrato = widget.contrato;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contract header
                _buildContractHeader(contrato),
                const SizedBox(height: 24),
                
                // Property information
                _buildSectionTitle('Información del Inmueble'),
                _buildPropertyInfo(contrato),
                const SizedBox(height: 24),
                
                // Contract details
                _buildSectionTitle('Detalles del Contrato'),
                _buildContractDetails(contrato),
                const SizedBox(height: 24),
                
                // Contract conditions
                _buildSectionTitle('Condiciones del Contrato'),
                _buildContractConditions(contrato),
                const SizedBox(height: 24),
                
                // Blockchain information
                _buildSectionTitle('Información Blockchain'),
                _buildBlockchainInfo(contrato),
                const SizedBox(height: 24),
                
                // Action buttons
                _buildActionButtons(contrato, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContractHeader(ContratoModel contrato) {
    // Get status color
    Color statusColor;
    switch (contrato.estado.toLowerCase()) {
      case 'pendiente':
        statusColor = Colors.orange;
        break;
      case 'aprobado':
        statusColor = Colors.green;
        break;
      case 'activo':
        statusColor = Colors.blue;
        break;
      case 'rechazado':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    contrato.inmueble?.nombre ?? 'Inmueble sin nombre',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(contrato.estado),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Contrato #${contrato.id}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildPropertyInfo(ContratoModel contrato) {
    final inmueble = contrato.inmueble;
    
    if (inmueble == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Información del inmueble no disponible'),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              inmueble.nombre,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              inmueble.detalle.toString(),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Tipo: ${inmueble.tipoInmueble}',
              style: const TextStyle(fontSize: 16),
            ),
            if (inmueble.detalle != null && inmueble.detalle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                inmueble.detalle!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContractDetails(ContratoModel contrato) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fecha Inicio:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        dateFormat.format(contrato.fechaInicio),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fecha Fin:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        dateFormat.format(contrato.fechaFin),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Monto Mensual: \$${contrato.monto.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            if (contrato.fechaPago != null) ...[
              const SizedBox(height: 12),
              Text(
                'Fecha de Pago: ${dateFormat.format(contrato.fechaPago!)}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
            ],
            if (contrato.detalle != null && contrato.detalle!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Detalles Adicionales:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                contrato.detalle!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContractConditions(ContratoModel contrato) {
    if (contrato.condicionales.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay condiciones especiales para este contrato.'),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < contrato.condicionales.length; i++) ...[
              if (i > 0) const Divider(),
              _buildConditionItem(contrato.condicionales[i], i + 1),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConditionItem(CondicionalModel condicion, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Condición $index: ${condicion.tipoCondicion}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            condicion.descripcion,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Acción: ${condicion.accion}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockchainInfo(ContratoModel contrato) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contrato.blockchainAddress != null && contrato.blockchainAddress!.isNotEmpty) ...[
              const Text(
                'Dirección del Smart Contract:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                contrato.blockchainAddress!,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement view on blockchain explorer
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Funcionalidad en desarrollo: Ver en explorador blockchain'),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Ver en Explorador'),
              ),
            ] else ...[
              const Text(
                'Este contrato aún no está registrado en la blockchain.',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Una vez que el contrato sea aprobado y se realice el pago, se generará automáticamente un smart contract en la blockchain.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ContratoModel contrato, ContratoProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (contrato.estado.toLowerCase() == 'pendiente') ...[
              ElevatedButton.icon(
                onPressed: () {
                  _showApprovalDialog(context, contrato, provider);
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('Responder al Contrato'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ] else if (contrato.estado.toLowerCase() == 'aprobado' && contrato.fechaPago == null) ...[
              ElevatedButton.icon(
                onPressed: () {
                  _showPaymentDialog(context, contrato, provider);
                },
                icon: const Icon(Icons.payment),
                label: const Text('Realizar Pago Inicial'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ] else if (contrato.estado.toLowerCase() == 'activo') ...[
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement payment history
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Funcionalidad en desarrollo: Ver historial de pagos'),
                    ),
                  );
                },
                icon: const Icon(Icons.history),
                label: const Text('Ver Historial de Pagos'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'aprobado':
        return 'Aprobado';
      case 'activo':
        return 'Activo';
      case 'rechazado':
        return 'Rechazado';
      default:
        return status;
    }
  }

  void _showApprovalDialog(
      BuildContext context, ContratoModel contrato, ContratoProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Responder al Contrato'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Deseas aceptar o rechazar el contrato para "${contrato.inmueble?.nombre ?? 'este inmueble'}"?',
            ),
            const SizedBox(height: 16),
            const Text(
              'Al aceptar, deberás realizar el pago del primer mes para activar el contrato.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
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
              await provider.updateContratoClienteAprobado(contrato.id, false);
              Navigator.pop(context); // Return to contracts list
            },
            child: const Text(
              'Rechazar',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.updateContratoClienteAprobado(contrato.id, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(
      BuildContext context, ContratoModel contrato, ContratoProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Realizar Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vas a realizar el pago del primer mes de alquiler por un monto de \$${contrato.monto.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 16),
            const Text(
              'Este pago activará tu contrato de alquiler.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Selecciona el método de pago:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Payment methods
            ListTile(
              title: const Text('Pago Convencional'),
              leading: Radio<String>(
                value: 'convencional',
                groupValue: 'convencional', // Default selected
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: const Text('Pago con Blockchain'),
              subtitle: const Text('Próximamente'),
              leading: Radio<String>(
                value: 'blockchain',
                groupValue: 'convencional',
                onChanged: null, // Disabled for now
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.registrarPagoContrato(contrato.id, DateTime.now());
              if (success) {
                Navigator.pop(context); // Return to contracts list
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Pago'),
          ),
        ],
      ),
    );
  }
}