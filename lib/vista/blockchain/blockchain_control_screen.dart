import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../controllers_providers/blockchain_provider.dart';
import '../../controllers_providers/contrato_provider.dart';
import '../../controllers_providers/pago_provider.dart';
import '../../models/contrato_model.dart';
import '../../models/pago_model.dart';
import '../components/Loading.dart';

class BlockchainControlScreen extends StatefulWidget {
  const BlockchainControlScreen({Key? key}) : super(key: key);

  @override
  State<BlockchainControlScreen> createState() =>
      _BlockchainControlScreenState();
}

class _BlockchainControlScreenState extends State<BlockchainControlScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isBlockchainInitialized = false;
  List<ContratoModel> _contratos = [];
  List<PagoModel> _pagos = [];
  Map<int, Map<String, dynamic>?> _blockchainContractDetails = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeBlockchain();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeBlockchain() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final blockchainProvider = context.read<BlockchainProvider>();

      if (!blockchainProvider.isInitialized) {
        // Get blockchain configuration from .env
        final rpcUrl = dotenv.env['BLOCKCHAIN_RPC_URL_LOCAL'] ?? '';
        final privateKey = dotenv.env['MNEMONIC'] ?? '';
        final chainId =
            int.tryParse(dotenv.env['BLOCKCHAIN_CHAIN_ID_LOCAL'] ?? '0') ?? 0;

        if (rpcUrl.isEmpty || privateKey.isEmpty || chainId == 0) {
          setState(() {
            _errorMessage = 'Configuración blockchain incompleta en .env';
            _isLoading = false;
          });
          return;
        }

        final success = await blockchainProvider.initialize(
          rpcUrl: rpcUrl,
          privateKey: privateKey,
          chainId: chainId,
        );

        if (!success) {
          setState(() {
            _errorMessage =
                'Error al inicializar blockchain: ${blockchainProvider.message}';
            _isLoading = false;
          });
          return;
        }
      }

      setState(() {
        _isBlockchainInitialized = blockchainProvider.isInitialized;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al inicializar blockchain: $e';
      });
      print('Error initializing blockchain: $_errorMessage');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load contracts
      await context.read<ContratoProvider>().loadContratosByClienteId();
      _contratos = context.read<ContratoProvider>().contratos;

      // Load payments
      await context.read<PagoProvider>().loadPagosByClienteId();
      _pagos = context.read<PagoProvider>().pagos;

      // Load blockchain details for contracts
      if (_isBlockchainInitialized) {
        for (var contrato in _contratos) {
          if (contrato.blockchainAddress != null &&
              contrato.blockchainAddress!.isNotEmpty) {
            try {
              final details = await context
                  .read<BlockchainProvider>()
                  .getContractDetails(contrato.id);
              setState(() {
                _blockchainContractDetails[contrato.id] = details;
              });
            } catch (e) {
              print(
                'Error loading blockchain details for contract ${contrato.id}: $e',
              );
            }
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar datos: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control Blockchain'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Estado', icon: Icon(Icons.dashboard)),
            Tab(text: 'Contratos', icon: Icon(Icons.description)),
            Tab(text: 'Pagos', icon: Icon(Icons.payment)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body:
          _isLoading
              ? Loading(title: 'Cargando datos blockchain...')
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _initializeBlockchain,
                      child: Text('Reintentar'),
                    ),
                  ],
                ),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildStatusTab(),
                  _buildContractsTab(),
                  _buildPaymentsTab(),
                ],
              ),
    );
  }

  Widget _buildStatusTab() {
    final blockchainProvider = context.watch<BlockchainProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estado de la Conexión',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildStatusRow(
                    'Servicio Blockchain',
                    blockchainProvider.isInitialized
                        ? 'Conectado'
                        : 'Desconectado',
                    blockchainProvider.isInitialized
                        ? Colors.green
                        : Colors.red,
                  ),
                  _buildStatusRow(
                    'Red',
                    dotenv.env['BLOCKCHAIN_RPC_URL_LOCAL']?.contains(
                              '127.0.0.1',
                            ) ==
                            true
                        ? 'Local (Desarrollo)'
                        : dotenv.env['BLOCKCHAIN_RPC_URL_TESTNET']?.contains(
                              'sepolia',
                            ) ==
                            true
                        ? 'Testnet (Sepolia)'
                        : 'Mainnet',
                    Colors.blue,
                  ),
                  _buildStatusRow(
                    'Chain ID',
                    dotenv.env['BLOCKCHAIN_CHAIN_ID_LOCAL'] ?? 'No disponible',
                    Colors.blue,
                  ),
                  if (blockchainProvider.contractAddress != null)
                    _buildStatusRow(
                      'Dirección del Contrato',
                      blockchainProvider.contractAddress!,
                      Colors.blue,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estadísticas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildStatusRow(
                    'Contratos en Blockchain',
                    _contratos
                        .where(
                          (c) =>
                              c.blockchainAddress != null &&
                              c.blockchainAddress!.isNotEmpty,
                        )
                        .length
                        .toString(),
                    Colors.blue,
                  ),
                  _buildStatusRow(
                    'Pagos en Blockchain',
                    _pagos
                        .where(
                          (p) =>
                              p.blockChainId != null &&
                              p.blockChainId!.isNotEmpty,
                        )
                        .length
                        .toString(),
                    Colors.blue,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mensajes del Sistema',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      blockchainProvider.message ?? 'No hay mensajes recientes',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractsTab() {
    if (_contratos.isEmpty) {
      return const Center(child: Text('No hay contratos disponibles'));
    }

    // Filter contracts with blockchain address
    final blockchainContracts =
        _contratos
            .where(
              (c) =>
                  c.blockchainAddress != null &&
                  c.blockchainAddress!.isNotEmpty,
            )
            .toList();

    if (blockchainContracts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'No hay contratos registrados en blockchain',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: blockchainContracts.length,
      itemBuilder: (context, index) {
        final contrato = blockchainContracts[index];
        final blockchainDetails = _blockchainContractDetails[contrato.id];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            title: Text('Contrato #${contrato.id}'),
            subtitle: Text(contrato.inmueble?.nombre ?? 'Sin título'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detalles del Contrato',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Estado', contrato.estado),
                    _buildDetailRow(
                      'Monto',
                      '\$${contrato.monto.toStringAsFixed(2)}',
                    ),
                    _buildDetailRow(
                      'Fecha Inicio',
                      _formatDate(contrato.fechaInicio),
                    ),
                    _buildDetailRow(
                      'Fecha Fin',
                      _formatDate(contrato.fechaFin),
                    ),
                    _buildDetailRow(
                      'Dirección Blockchain',
                      contrato.blockchainAddress ?? 'No disponible',
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Detalles en Blockchain',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),

                    if (blockchainDetails != null) ...[
                      _buildDetailRow(
                        'Propietario',
                        blockchainDetails['landlord'] ?? 'No disponible',
                      ),
                      _buildDetailRow(
                        'Inquilino',
                        blockchainDetails['tenant'] ?? 'No disponible',
                      ),
                      _buildDetailRow(
                        'Monto en Blockchain',
                        '\$${blockchainDetails['rentAmount']?.toString() ?? 'No disponible'}',
                      ),
                      _buildDetailRow(
                        'Estado en Blockchain',
                        _getBlockchainStateString(blockchainDetails['state']),
                      ),
                      if (blockchainDetails['lastPaymentDate'] != null)
                        _buildDetailRow(
                          'Último Pago',
                          _formatDate(blockchainDetails['lastPaymentDate']),
                        ),
                    ] else ...[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Detalles de blockchain no disponibles',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab() {
    if (_pagos.isEmpty) {
      return const Center(child: Text('No hay pagos disponibles'));
    }

    // Filter payments with blockchain ID
    final blockchainPayments =
        _pagos
            .where((p) => p.blockChainId != null && p.blockChainId!.isNotEmpty)
            .toList();

    if (blockchainPayments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'No hay pagos registrados en blockchain',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: blockchainPayments.length,
      itemBuilder: (context, index) {
        final pago = blockchainPayments[index];

        // Find associated contract
        final contrato = _contratos.firstWhere(
          (c) => c.id == pago.contratoId,
          orElse:
              () => ContratoModel(
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Chip(
                      label: Text(pago.estado),
                      backgroundColor:
                          pago.estado == 'completado'
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                      labelStyle: TextStyle(
                        color:
                            pago.estado == 'completado'
                                ? Colors.green.shade800
                                : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Contrato: ${contrato.inmueble?.nombre ?? "Propiedad"}',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fecha de pago: ${_formatDate(pago.fechaPago)}',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Monto: \$${pago.monto.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Detalles Blockchain',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.link, size: 16, color: Colors.blue),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'ID Transacción: ${pago.blockChainId}',
                        style: TextStyle(fontSize: 14, color: Colors.blue),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            value,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getBlockchainStateString(int? state) {
    if (state == null) return 'Desconocido';

    switch (state) {
      case 0:
        return 'Pendiente';
      case 1:
        return 'Aprobado';
      case 2:
        return 'Activo';
      case 3:
        return 'Terminado';
      case 4:
        return 'Expirado';
      default:
        return 'Desconocido';
    }
  }
}
