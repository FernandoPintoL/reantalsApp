import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../controllers_providers/pago_provider.dart';
import '../../controllers_providers/contrato_provider.dart';
import '../../controllers_providers/blockchain_provider.dart';
import '../../models/pago_model.dart';
import '../../models/contrato_model.dart';
import '../components/Loading.dart';

class BlockchainPaymentScreen extends StatefulWidget {
  final int contratoId;

  const BlockchainPaymentScreen({
    Key? key,
    required this.contratoId,
  }) : super(key: key);

  @override
  State<BlockchainPaymentScreen> createState() => _BlockchainPaymentScreenState();
}

class _BlockchainPaymentScreenState extends State<BlockchainPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();

  bool _isLoading = true;
  ContratoModel? _contrato;
  String? _errorMessage;
  bool _isBlockchainInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load contract details
      await context.read<ContratoProvider>().loadContratoById(widget.contratoId);
      _contrato = context.read<ContratoProvider>().selectedContrato;

      if (_contrato == null) {
        setState(() {
          _errorMessage = 'No se pudo cargar el contrato';
          _isLoading = false;
        });
        return;
      }

      // Set default amount from contract
      _montoController.text = _contrato!.monto.toString();

      // Check if blockchain is initialized
      _isBlockchainInitialized = context.read<BlockchainProvider>().isInitialized;

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

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final monto = double.parse(_montoController.text);

      // Create payment model
      final pago = PagoModel(
        contratoId: widget.contratoId,
        monto: monto,
        fechaPago: DateTime.now(),
        descripcion: _descripcionController.text,
        estado: 'pendiente', // Will be updated to 'completado' after blockchain processing
      );

      // Process payment through blockchain
      final success = await context.read<PagoProvider>().createPagoBlockchain(pago);

      if (success) {
        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<PagoProvider>().message ?? 'Pago procesado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        // Show error message
        setState(() {
          _errorMessage = context.read<PagoProvider>().message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al procesar el pago: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago con Blockchain'),
      ),
      body: _isLoading
          ? Loading(title: 'Cargando datos...')
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Blockchain info card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Información Blockchain',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  'Estado Blockchain',
                                  _isBlockchainInitialized
                                      ? 'Conectado'
                                      : 'No inicializado',
                                  _isBlockchainInitialized
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                _buildInfoRow(
                                  'Red',
                                  dotenv.env['BLOCKCHAIN_RPC_URL_LOCAL']?.contains('127.0.0.1') == true
                                      ? 'Local (Desarrollo)'
                                      : dotenv.env['BLOCKCHAIN_RPC_URL_TESTNET']?.contains('sepolia') == true
                                          ? 'Testnet (Sepolia)'
                                          : 'Mainnet',
                                  Colors.blue,
                                ),
                                _buildInfoRow(
                                  'Chain ID',
                                  dotenv.env['BLOCKCHAIN_CHAIN_ID_LOCAL'] ?? 'No disponible',
                                  Colors.blue,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Nota: El servicio blockchain se inicializará automáticamente al realizar el pago si aún no está inicializado.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Contract info card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Información del Contrato',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  'Inmueble',
                                  _contrato?.inmueble?.nombre ?? 'No disponible',
                                  Colors.black,
                                ),
                                _buildInfoRow(
                                  'Propietario',
                                  _contrato?.propietario?.name ?? 'No disponible',
                                  Colors.black,
                                ),
                                _buildInfoRow(
                                  'Cliente',
                                  _contrato?.cliente?.name ?? 'No disponible',
                                  Colors.black,
                                ),
                                _buildInfoRow(
                                  'Monto Mensual',
                                  '\$${_contrato?.monto.toStringAsFixed(2) ?? '0.00'}',
                                  Colors.black,
                                ),
                                _buildInfoRow(
                                  'Estado',
                                  _contrato?.estado ?? 'No disponible',
                                  _contrato?.estado == 'activo' ? Colors.green : Colors.orange,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Payment form
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Detalles del Pago',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _montoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Monto',
                                    prefixText: '\$',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingrese un monto';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Por favor ingrese un número válido';
                                    }
                                    if (double.parse(value) <= 0) {
                                      return 'El monto debe ser mayor a cero';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _descripcionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Descripción',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _submitPayment,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text(
                                      'REALIZAR PAGO CON BLOCKCHAIN',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label, 
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
