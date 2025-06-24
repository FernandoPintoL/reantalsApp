import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/contrato_model.dart';
import '../../../controllers_providers/contrato_provider.dart';
import '../administrar_contrato_screen.dart';

class ContratosListScreen extends StatefulWidget {
  const ContratosListScreen({Key? key}) : super(key: key);

  @override
  State<ContratosListScreen> createState() => _ContratosListScreenState();
}

class _ContratosListScreenState extends State<ContratosListScreen> {
  final dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadContratos();
  }

  Future<void> _loadContratos() async {
    try {
      context.read<ContratoProvider>().isLoading = true;
      await context.read<ContratoProvider>().loadContratosByPropietarioId();
      if(!mounted) return;
      context.read<ContratoProvider>().isLoading = false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar los contratos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Contratos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContratos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Consumer<ContratoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.contratos.isEmpty) {
            return const Center(
              child: Text('No tienes contratos registrados'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.contratos.length,
            itemBuilder: (context, index) {
              final contrato = provider.contratos[index];
              return _buildContratoCard(contrato);
            },
          );
        },
      ),
    );
  }

  Widget _buildContratoCard(ContratoModel contrato) {
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
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdministrarContratoScreen(contrato: contrato),
            ),
          );
        },
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
                        fontSize: 18,
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
                'Cliente: ${contrato.cliente?.name ?? "Cliente desconocido"}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Fecha inicio: ${dateFormat.format(contrato.fechaInicio)}',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'Fecha fin: ${dateFormat.format(contrato.fechaFin)}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Monto: \$${contrato.monto.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              if (contrato.fechaPago != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Último pago: ${dateFormat.format(contrato.fechaPago!)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
              ],
            ],
          ),
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
}