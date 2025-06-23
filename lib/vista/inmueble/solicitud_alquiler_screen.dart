import 'package:flutter/material.dart';
import '../../models/inmueble_model.dart';
import '../../models/servicio_basico_model.dart';
import '../../models/session_model.dart';
import '../../models/solicitud_alquiler_model.dart';
import '../../models/user_model.dart';
import '../../models/galeria_inmueble_model.dart';
import '../../negocio/SessionNegocio.dart';
import '../../negocio/UserNegocio.dart';
import '../../controllers_providers/inmueble_provider.dart';
import '../../controllers_providers/solicitud_alquiler_provider.dart';
import '../../services/ApiService.dart';
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

  List<ServicioBasicoModel> _serviciosBasicos = [];
  List<GaleriaInmuebleModel> _galeriaInmueble = [];

  @override
  void initState() {
    super.initState();
    _loadServicios();
    _loadGaleriaInmueble();
  }

  Future<void> _loadGaleriaInmueble() async {
    try {
      List<GaleriaInmuebleModel> result = await context.read<InmuebleProvider>().loadInmuebleGaleria(widget.inmueble.id);
      setState(() {
        _galeriaInmueble = result;
      });
    } catch (e) {
      print('Error loading gallery images: $e');
    }
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
      try {
        // Create solicitud model
        final solicitud = SolicitudAlquilerModel(
          inmuebleId: widget.inmueble.id,
          userId: context.read<SolicitudAlquilerProvider>().currentUser!.id,
          serviciosBasicos: selectedServices,
          mensaje: _mensajeController.text,
          inmueble: widget.inmueble
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Alquiler de Inmueble'),
      ),
      body: context.watch<SolicitudAlquilerProvider>().isLoading
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
                            String photoPath;

                            // Handle different types of gallery items

                            final String imagePath = '${ApiService.getInstance().baseUrlImage}/${image.photoPath}';

                            return Container(
                              width: 200,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.error, color: Colors.red),
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
