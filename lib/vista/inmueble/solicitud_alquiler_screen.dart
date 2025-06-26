import 'package:flutter/material.dart';
import '../../models/inmueble_model.dart';
import '../../models/servicio_basico_model.dart';
import '../../models/solicitud_alquiler_model.dart';
import '../../models/galeria_inmueble_model.dart';
import '../../controllers_providers/inmueble_provider.dart';
import '../../controllers_providers/solicitud_alquiler_provider.dart';
import '../../services/ApiService.dart';
import 'package:provider/provider.dart';

class SolicitudAlquilerScreen extends StatefulWidget {
  final InmuebleModel inmueble;

  const SolicitudAlquilerScreen({Key? key, required this.inmueble})
    : super(key: key);

  @override
  State<SolicitudAlquilerScreen> createState() =>
      _SolicitudAlquilerScreenState();
}

class _SolicitudAlquilerScreenState extends State<SolicitudAlquilerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mensajeController = TextEditingController();

  List<ServicioBasicoModel> _serviciosBasicos = [];
  List<GaleriaInmuebleModel> _galeriaInmueble = [];

  // Helper method to check if a service is included in the property
  bool _isServiceInProperty(ServicioBasicoModel service) {
    if (widget.inmueble.servicios_basicos == null) return false;

    for (var propertyService in widget.inmueble.servicios_basicos!) {
      if (service.id == propertyService.id || 
          service.nombre.toLowerCase() == propertyService.nombre.toLowerCase()) {
        return true;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadServicios();
      _loadGaleriaInmueble();
    });
  }

  Future<void> _loadGaleriaInmueble() async {
    try {
      List<GaleriaInmuebleModel> result = await context
          .read<InmuebleProvider>()
          .loadInmuebleGaleria(widget.inmueble.id);
      setState(() {
        _galeriaInmueble = result;
      });
    } catch (e) {
      print('Error loading gallery images: $e');
    }
  }

  void _loadServicios() {
    // Load default services
    List<ServicioBasicoModel> defaultServices = ServicioBasicoModel.getDefaultServicios();

    // Check which services are already registered with the property
    if (widget.inmueble.servicios_basicos != null && widget.inmueble.servicios_basicos!.isNotEmpty) {
      // Mark services that are already registered with the property
      for (var defaultService in defaultServices) {
        // Check if this service exists in the property's services
        for (var propertyService in widget.inmueble.servicios_basicos!) {
          if (defaultService.id == propertyService.id || 
              defaultService.nombre.toLowerCase() == propertyService.nombre.toLowerCase()) {
            // Mark this service as pre-selected
            defaultService.isSelected = true;
            break;
          }
        }
      }
    }

    setState(() {
      _serviciosBasicos = defaultServices;
    });
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      if (context.read<SolicitudAlquilerProvider>().currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debe iniciar sesión para solicitar un alquiler'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get selected services
      final selectedServices =
          _serviciosBasicos.where((s) => s.isSelected).toList();

      if (selectedServices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debe seleccionar al menos un servicio básico'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      try {
        // Create solicitud model
        final solicitud = SolicitudAlquilerModel(
          inmuebleId: widget.inmueble.id,
          userId: context.read<SolicitudAlquilerProvider>().currentUser!.id,
          servicios_basicos: selectedServices,
          mensaje: _mensajeController.text,
          inmueble: widget.inmueble,
        );

        // Use the provider to submit the request
        final provider = Provider.of<SolicitudAlquilerProvider>(
          context,
          listen: false,
        );
        final success = await provider.createSolicitudAlquiler(solicitud, context: context);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  provider.message ?? 'Solicitud enviada exitosamente',
                ),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  provider.message ?? 'Error al enviar la solicitud',
                ),
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar Alquiler de Inmueble')),
      body:
          context.watch<SolicitudAlquilerProvider>().isLoading
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
                                  Text(
                                    'Habitaciones: ${widget.inmueble.numHabitacion}',
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.stairs, size: 16),
                                  const SizedBox(width: 4),
                                  Text('Piso: ${widget.inmueble.numPiso}'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Precio: \$${widget.inmueble.precio.toStringAsFixed(2)}',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Property images gallery
                      if (_galeriaInmueble.isNotEmpty) ...[
                        Text(
                          'Imágenes del Inmueble',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _galeriaInmueble.length,
                            itemBuilder: (context, index) {
                              final image = _galeriaInmueble[index];
                              final String imagePath =
                                  '${ApiService.getInstance().baseUrlImage}/${image.photoPath}';
                              return Container(
                                width: 200,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imagePath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          Icons.error,
                                          color: Colors.red,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

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
                            title: Row(
                              children: [
                                Text(servicio.nombre),
                                if (servicio.isSelected && _isServiceInProperty(servicio))
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green.shade300),
                                    ),
                                    child: const Text(
                                      'Incluido',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
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
                            tileColor: _isServiceInProperty(servicio) ? Colors.green.shade50 : null,
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
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
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
