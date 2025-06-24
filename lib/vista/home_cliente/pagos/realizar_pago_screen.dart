import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers_providers/pago_provider.dart';
import '../../../controllers_providers/blockchain_provider.dart';
import '../../../models/pago_model.dart';
import '../../../models/contrato_model.dart';

class RealizarPagoScreen extends StatefulWidget {
  final PagoModel pago;
  final ContratoModel contrato;

  const RealizarPagoScreen({
    Key? key,
    required this.pago,
    required this.contrato,
  }) : super(key: key);

  @override
  State<RealizarPagoScreen> createState() => _RealizarPagoScreenState();
}

class _RealizarPagoScreenState extends State<RealizarPagoScreen> {
  bool _isLoading = false;
  bool _blockchainEnabled = false;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _checkBlockchainStatus();
  }

  Future<void> _checkBlockchainStatus() async {
    final blockchainProvider = context.read<BlockchainProvider>();
    setState(() {
      _blockchainEnabled = blockchainProvider.isInitialized;
    });
  }

  Future<void> _realizarPago() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Actualizar el estado del pago a 'completado'
      final success = await context.read<PagoProvider>().updatePagoEstado(
        widget.pago.id,
        'completado',
      );

      if (success) {
        // Mostrar mensaje de éxito y volver a la pantalla anterior
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago realizado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Volver con resultado exitoso
      } else {
        // Mostrar mensaje de error
        setState(() {
          _errorMessage = context.read<PagoProvider>().message ?? 'Error al realizar el pago';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al realizar el pago: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realizar Pago'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Detalles del pago
                    Card(
                      margin: const EdgeInsets.only(bottom: 24),
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
                            _buildInfoRow('Propiedad:', widget.contrato.inmueble?.nombre ?? 'Propiedad'),
                            _buildInfoRow('Monto a pagar:', '\$${widget.pago.monto.toStringAsFixed(2)}'),
                            _buildInfoRow('Fecha de pago:', _formatDate(widget.pago.fechaPago)),
                            _buildInfoRow('Propietario:', widget.contrato.inmueble?.propietario?.name ?? 'Propietario'),
                          ],
                        ),
                      ),
                    ),

                    // Método de pago
                    Text(
                      'Método de Pago',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    // Opciones de pago
                    Card(
                      child: Column(
                        children: [
                          RadioListTile<bool>(
                            title: const Text('Pago con Blockchain'),
                            subtitle: Text(_blockchainEnabled 
                              ? 'Pago seguro mediante contrato inteligente' 
                              : 'No disponible - Wallet no configurada'),
                            value: true,
                            groupValue: _blockchainEnabled,
                            onChanged: _blockchainEnabled ? (_) {} : null,
                            activeColor: Colors.green,
                          ),
                          const Divider(),
                          RadioListTile<bool>(
                            title: const Text('Pago Tradicional'),
                            subtitle: const Text('Registrar pago realizado por otro medio'),
                            value: false,
                            groupValue: !_blockchainEnabled,
                            onChanged: (_) {},
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),
                    ),

                    // Mensaje de error
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Botón de pago
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _realizarPago,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Confirmar Pago',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}