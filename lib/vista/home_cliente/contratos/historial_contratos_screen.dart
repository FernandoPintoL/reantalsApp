import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/contrato_model.dart';
import '../../../controllers_providers/contrato_provider.dart';
import '../../components/Loading.dart';
import 'detalle_contrato_screen.dart';

class HistorialContratosScreen extends StatefulWidget {
  const HistorialContratosScreen({Key? key}) : super(key: key);

  @override
  State<HistorialContratosScreen> createState() => _HistorialContratosScreenState();
}

class _HistorialContratosScreenState extends State<HistorialContratosScreen> {
  List<ContratoModel> _contratosHistoricos = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContratos();
    });
  }

  Future<void> _loadContratos() async {
    try {
      context.read<ContratoProvider>().isLoading = true;
      // Cargar todos los contratos del usuario
      await context.read<ContratoProvider>().loadContratosByClienteId();
      final contratos = context.read<ContratoProvider>().contratos;
      
      // Filtrar solo contratos históricos (finalizados o cancelados)
      _contratosHistoricos = contratos.where((c) => 
        c.estado.toLowerCase() == 'finalizado' || 
        c.estado.toLowerCase() == 'cancelado' ||
        (c.estado.toLowerCase() == 'activo' && c.fechaFin.isBefore(DateTime.now()))
      ).toList();
      
      // Ordenar por fecha de fin (más reciente primero)
      _contratosHistoricos.sort((a, b) => b.fechaFin.compareTo(a.fechaFin));
    } catch (e) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los contratos: $e')),
      );
    } finally {
      if(!mounted) return;
      context.read<ContratoProvider>().isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Contratos del Cliente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContratos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: context.watch<ContratoProvider>().isLoading
          ? Loading(title: 'Cargando historial de contratos...')
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_contratosHistoricos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tienes contratos finalizados',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _contratosHistoricos.length,
      itemBuilder: (context, index) {
        final contrato = _contratosHistoricos[index];
        return _buildContratoCard(context, contrato);
      },
    );
  }

  Widget _buildContratoCard(BuildContext context, ContratoModel contrato) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    // Determinar el estado real del contrato
    String estadoMostrado = contrato.estado;
    if (contrato.estado.toLowerCase() == 'activo' && contrato.fechaFin.isBefore(DateTime.now())) {
      estadoMostrado = 'Finalizado';
    }
    
    // Get status color
    Color statusColor;
    switch (estadoMostrado.toLowerCase()) {
      case 'finalizado':
        statusColor = Colors.green;
        break;
      case 'cancelado':
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
                    contrato.inmueble?.nombre ?? 'Inmueble sin nombre',
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
                    estadoMostrado,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Contract info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dates and amount
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
                            style: const TextStyle(fontSize: 14),
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
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Monto Mensual: \$${contrato.monto.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                
                // Contract details if available
                if (contrato.detalle != null && contrato.detalle!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Detalles:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    contrato.detalle!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Action button to view details
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        // Navigate to contract details screen
                        context.read<ContratoProvider>().selectContrato(contrato);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetalleContratoScreen(
                              contrato: contrato,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('Ver Detalles'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}