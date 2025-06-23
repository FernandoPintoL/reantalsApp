import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/solicitud_alquiler_model.dart';
import '../../../models/contrato_model.dart';
import '../../../controllers_providers/contrato_provider.dart';

class CrearContratoScreen extends StatefulWidget {
  final SolicitudAlquilerModel solicitud;

  const CrearContratoScreen({
    Key? key,
    required this.solicitud,
  }) : super(key: key);

  @override
  State<CrearContratoScreen> createState() => _CrearContratoScreenState();
}

class _CrearContratoScreenState extends State<CrearContratoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _detalleController = TextEditingController();
  final _montoController = TextEditingController();
  
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 365));
  
  List<CondicionalModel> _condicionales = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set initial monto based on property price
    if (widget.solicitud.inmueble != null) {
      _montoController.text = widget.solicitud.inmueble!.precio.toString();
    }
    
    // Add default conditionals
    _condicionales = [
      CondicionalModel(
        id: 1,
        descripcion: 'Retraso en el pago mensual',
        tipoCondicion: 'retraso_pago',
        accion: 'multa',
        parametros: {'dias_retraso': 5, 'porcentaje_multa': 10},
      ),
      CondicionalModel(
        id: 2,
        descripcion: 'Daños a la propiedad',
        tipoCondicion: 'daños',
        accion: 'reparacion',
        parametros: {'responsable': 'inquilino'},
      ),
    ];
  }

  @override
  void dispose() {
    _detalleController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _selectFechaInicio(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _fechaInicio) {
      setState(() {
        _fechaInicio = picked;
        // Ensure fechaFin is after fechaInicio
        if (_fechaFin.isBefore(_fechaInicio)) {
          _fechaFin = _fechaInicio.add(const Duration(days: 365));
        }
      });
    }
  }

  Future<void> _selectFechaFin(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaFin,
      firstDate: _fechaInicio,
      lastDate: _fechaInicio.add(const Duration(days: 365 * 10)),
    );
    if (picked != null && picked != _fechaFin) {
      setState(() {
        _fechaFin = picked;
      });
    }
  }

  void _addCondicional() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Condicional'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Ej: Retraso en el pago mensual',
                ),
                maxLines: 2,
                onChanged: (value) {
                  // Store temporarily
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipo de Condición',
                ),
                items: const [
                  DropdownMenuItem(value: 'retraso_pago', child: Text('Retraso en el Pago')),
                  DropdownMenuItem(value: 'daños', child: Text('Daños a la Propiedad')),
                  DropdownMenuItem(value: 'incumplimiento', child: Text('Incumplimiento de Contrato')),
                  DropdownMenuItem(value: 'otro', child: Text('Otro')),
                ],
                onChanged: (value) {
                  // Store temporarily
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Acción a Tomar',
                ),
                items: const [
                  DropdownMenuItem(value: 'multa', child: Text('Aplicar Multa')),
                  DropdownMenuItem(value: 'reparacion', child: Text('Reparación')),
                  DropdownMenuItem(value: 'rescision', child: Text('Rescisión de Contrato')),
                  DropdownMenuItem(value: 'otro', child: Text('Otra Acción')),
                ],
                onChanged: (value) {
                  // Store temporarily
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // For simplicity, just add a default conditional
              setState(() {
                _condicionales.add(
                  CondicionalModel(
                    id: _condicionales.length + 1,
                    descripcion: 'Nueva condición',
                    tipoCondicion: 'otro',
                    accion: 'otro',
                    parametros: {},
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _removeCondicional(int index) {
    setState(() {
      _condicionales.removeAt(index);
    });
  }

  Future<void> _submitContrato() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final provider = Provider.of<ContratoProvider>(context, listen: false);
        
        final success = await provider.createContratoFromSolicitud(
          widget.solicitud,
          fechaInicio: _fechaInicio,
          fechaFin: _fechaFin,
          monto: double.parse(_montoController.text),
          detalle: _detalleController.text,
          condicionales: _condicionales,
        );
        
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.message ?? 'Contrato creado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.message ?? 'Error al crear el contrato'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al crear el contrato: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Contrato'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property and client info card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.solicitud.inmueble?.nombre ?? 'Inmueble sin nombre',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Cliente: ${widget.solicitud.cliente?.name ?? "Cliente desconocido"}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Email: ${widget.solicitud.cliente?.email ?? ""}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Teléfono: ${widget.solicitud.cliente?.telefono ?? ""}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Contract details section
                    Text(
                      'Detalles del Contrato',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    // Fecha inicio
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            controller: TextEditingController(
                              text: dateFormat.format(_fechaInicio),
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Fecha de Inicio',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            onTap: () => _selectFechaInicio(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            controller: TextEditingController(
                              text: dateFormat.format(_fechaFin),
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Fecha de Fin',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            onTap: () => _selectFechaFin(context),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Monto
                    TextFormField(
                      controller: _montoController,
                      decoration: const InputDecoration(
                        labelText: 'Monto Mensual',
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un monto';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Por favor ingrese un número válido';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Detalle
                    TextFormField(
                      controller: _detalleController,
                      decoration: const InputDecoration(
                        labelText: 'Detalles adicionales',
                        border: OutlineInputBorder(),
                        hintText: 'Ingrese detalles adicionales del contrato...',
                      ),
                      maxLines: 4,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Conditionals section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Condicionales',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        ElevatedButton.icon(
                          onPressed: _addCondicional,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Defina las condiciones que se aplicarán en caso de incumplimiento:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    
                    // Conditionals list
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _condicionales.length,
                      itemBuilder: (context, index) {
                        final condicional = _condicionales[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(condicional.descripcion),
                            subtitle: Text('Acción: ${_getAccionText(condicional.accion)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeCondicional(index),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitContrato,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Crear y Enviar Contrato',
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
  
  String _getAccionText(String accion) {
    switch (accion.toLowerCase()) {
      case 'multa':
        return 'Aplicar Multa';
      case 'reparacion':
        return 'Reparación';
      case 'rescision':
        return 'Rescisión de Contrato';
      default:
        return accion;
    }
  }
}