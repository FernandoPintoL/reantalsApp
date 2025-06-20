import 'package:flutter/material.dart';
import '../../models/inmueble_model.dart';
import '../../models/servicio_basico_model.dart';
import '../../models/session_model.dart';
import '../../models/solicitud_alquiler_model.dart';
import '../../models/user_model.dart';
import '../../negocio/SessionNegocio.dart';
import '../../negocio/UserNegocio.dart';
import '../../providers/inmueble_provider.dart';
import '../../providers/solicitud_alquiler_provider.dart';
import 'package:provider/provider.dart';

class SolicitudAlquilerScreen extends StatefulWidget {
  final InmuebleModel inmueble;

  const SolicitudAlquilerScreen({
    Key? key,
    required this.inmueble,
  }) : super(key: key);

  @override
  State<SolicitudAlquilerScreen> createState() => _SolicitudAlquilerScreenState();
}

class _SolicitudAlquilerScreenState extends State<SolicitudAlquilerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mensajeController = TextEditingController();
  final SessionNegocio _sessionNegocio = SessionNegocio();
  final UserNegocio _userNegocio = UserNegocio();

  List<ServicioBasicoModel> _serviciosBasicos = [];
  bool _isLoading = false;
  UserModel? _currentUser;
  SessionModelo? _sessionModel;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadServicios();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _sessionModel = await _sessionNegocio.getSession();
      if (_sessionModel != null && _sessionModel!.userId != null) {
        _currentUser = await _userNegocio.getUser(_sessionModel!.userId!);
      } else {
        _currentUser = null;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar el usuario: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _loadServicios() {
    // Load default services
    setState(() {
      _serviciosBasicos = ServicioBasicoModel.getDefaultServicios();
    });
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      if (_currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debe iniciar sesión para solicitar un alquiler'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get selected services
      final selectedServices = _serviciosBasicos.where((s) => s.isSelected).toList();

      if (selectedServices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debe seleccionar al menos un servicio básico'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Create solicitud model
        final solicitud = SolicitudAlquilerModel(
          inmuebleId: widget.inmueble.id,
          userId: _currentUser!.id,
          serviciosBasicos: selectedServices,
          mensaje: _mensajeController.text,
          cliente: _currentUser,
          inmueble: widget.inmueble,
        );

        // Use the provider to submit the request
        final provider = Provider.of<SolicitudAlquilerProvider>(context, listen: false);
        final success = await provider.createSolicitudAlquiler(solicitud);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.message ?? 'Solicitud enviada exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.message ?? 'Error al enviar la solicitud'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al enviar la solicitud: $e'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Alquiler'),
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
                    // Property info card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.inmueble.nombre,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.inmueble.detalle ?? 'Sin detalles',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.hotel, size: 16),
                                const SizedBox(width: 4),
                                Text('Habitaciones: ${widget.inmueble.numHabitacion}'),
                                const SizedBox(width: 16),
                                const Icon(Icons.stairs, size: 16),
                                const SizedBox(width: 4),
                                Text('Piso: ${widget.inmueble.numPiso}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Precio: \$${widget.inmueble.precio.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Services selection section
                    Text(
                      'Servicios Básicos Requeridos',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Seleccione los servicios básicos que necesita para este inmueble:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    // Services list
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _serviciosBasicos.length,
                      itemBuilder: (context, index) {
                        final servicio = _serviciosBasicos[index];
                        return CheckboxListTile(
                          title: Text(servicio.nombre),
                          subtitle: Text(servicio.descripcion ?? ''),
                          value: servicio.isSelected,
                          onChanged: (value) {
                            setState(() {
                              _serviciosBasicos[index] = ServicioBasicoModel(
                                id: servicio.id,
                                nombre: servicio.nombre,
                                descripcion: servicio.descripcion,
                                isSelected: value ?? false,
                              );
                            });
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Message input
                    Text(
                      'Mensaje Adicional',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Puede agregar un mensaje adicional para el propietario:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mensajeController,
                      decoration: const InputDecoration(
                        hintText: 'Escriba su mensaje aquí...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),

                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Enviar Solicitud',
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
}
