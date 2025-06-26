import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../controllers_providers/blockchain_provider.dart';
import '../services/websocket_admin_service.dart';
import '../services/socket_service.dart';
import 'websocket_status_widget.dart';

class BlockchainWebSocketDrawer extends StatefulWidget {
  const BlockchainWebSocketDrawer({Key? key}) : super(key: key);

  @override
  State<BlockchainWebSocketDrawer> createState() => _BlockchainWebSocketDrawerState();
}

class _BlockchainWebSocketDrawerState extends State<BlockchainWebSocketDrawer> {
  bool _isBlockchainInitialized = false;
  bool _showCodeExamples = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBlockchainStatus();
    });
  }

  Future<void> _checkBlockchainStatus() async {
    final blockchainProvider = context.read<BlockchainProvider>();
    setState(() {
      _isBlockchainInitialized = blockchainProvider.isInitialized;
    });
  }

  @override
  Widget build(BuildContext context) {
    final blockchainProvider = context.watch<BlockchainProvider>();
    final adminService = Provider.of<WebSocketAdminService>(context, listen: false);

    return Drawer(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Estado de Servicios',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Monitorea el estado de la blockchain y WebSocket',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Divider(),

                // Blockchain Status
                Text(
                  'Estado de Blockchain',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          dotenv.env['BLOCKCHAIN_RPC_URL_LOCAL']?.contains('127.0.0.1') == true
                              ? 'Local (Desarrollo)'
                              : dotenv.env['BLOCKCHAIN_RPC_URL_TESTNET']?.contains('sepolia') == true
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
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reinicializar'),
                              onPressed: () async {
                                await blockchainProvider.ensureInitialized();
                                _checkBlockchainStatus();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // WebSocket Status
                Text(
                  'Estado de WebSocket',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                WebSocketStatusWidget(
                  adminService: adminService,
                  showControls: true,
                  showStats: false,
                ),

                const SizedBox(height: 24),

                // How to use section
                Text(
                  'Cómo utilizar estos servicios',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Blockchain Provider',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Para utilizar el BlockchainProvider desde cualquier widget:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '1. Accede a la instancia singleton:',
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'final blockchainProvider = BlockchainProvider.instance;',
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '2. O utiliza Provider para acceder desde un widget:',
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'final blockchainProvider = context.read<BlockchainProvider>();',
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'WebSocket Service',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Para utilizar el WebSocketAdminService:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '1. Accede al servicio mediante Provider:',
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'final adminService = Provider.of<WebSocketAdminService>(context, listen: false);',
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: Icon(_showCodeExamples ? Icons.visibility_off : Icons.visibility),
                              label: Text(_showCodeExamples ? 'Ocultar ejemplos' : 'Ver ejemplos de código'),
                              onPressed: () {
                                setState(() {
                                  _showCodeExamples = !_showCodeExamples;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Code examples (collapsible)
                if (_showCodeExamples) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Ejemplos de Código',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ejemplo: Verificar estado de Blockchain',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '''
Future<void> checkBlockchainStatus() async {
  final blockchainProvider = BlockchainProvider.instance;
  
  // Asegurar que blockchain esté inicializado
  await blockchainProvider.ensureInitialized();
  
  // Verificar estado
  if (blockchainProvider.isInitialized) {
    print('Blockchain está conectado');
  } else {
    print('Blockchain no está conectado');
  }
}
''',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Ejemplo: Escuchar eventos WebSocket',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '''
void listenToWebSocketEvents() {
  final adminService = Provider.of<WebSocketAdminService>(
    context, 
    listen: false
  );
  
  // Escuchar cambios de estado
  adminService.connectionStatus.listen((status) {
    print('Estado de conexión: \$status');
  });
  
  // Escuchar eventos administrativos
  adminService.adminEvents.listen((event) {
    print('Evento recibido: \$event');
  });
}
''',
                              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            value,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}