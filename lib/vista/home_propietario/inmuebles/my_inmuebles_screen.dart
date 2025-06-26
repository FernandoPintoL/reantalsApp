import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../controllers_providers/inmueble_provider.dart';
import '../../../models/inmueble_model.dart';
import '../../components/Loading.dart';
import '../../components/image_profile_inmueble.dart';
import 'detalle_inmuebles.dart';

class MyInmueblesScreen extends StatefulWidget {
  const MyInmueblesScreen({Key? key}) : super(key: key);

  @override
  State<MyInmueblesScreen> createState() => _MyInmueblesScreenState();
}

class _MyInmueblesScreenState extends State<MyInmueblesScreen> {
  @override
  void initState() {
    super.initState();
    // Load properties belonging to the current user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InmuebleProvider>().loadInmueblesByPropietarioId();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Inmuebles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<InmuebleProvider>().loadInmueblesByPropietarioId();
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Consumer<InmuebleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Loading(title: 'Cargando inmuebles...');
          }

          if (provider.message != null && provider.myInmuebles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.loadInmueblesByPropietarioId();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (provider.myInmuebles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No tienes inmuebles registrados',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.loadInmueblesByPropietarioId();
                    },
                    child: const Text('Recargar Inmuebles'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  DetalleInmueblesScreen(isEditing: false),
                        ),
                      );
                    },
                    child: const Text('Crear Inmueble'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadInmueblesByPropietarioId(),
            child: ListView.builder(
              itemCount: provider.myInmuebles.length,
              itemBuilder: (context, index) {
                final inmueble = provider.myInmuebles[index];
                return _buildInmuebleCard(context, inmueble, provider);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<InmuebleProvider>().clear();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalleInmueblesScreen(isEditing: false),
            ),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Añadir Inmueble',
      ),
    );
  }

  Widget _buildInmuebleCard(
    BuildContext context,
    InmuebleModel inmueble,
    InmuebleProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property image or placeholder
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child:
                inmueble.tipoInmueble?.nombre != null
                    ? Center(
                      child: Text(
                        inmueble.tipoInmueble!.nombre,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                    : ImageProfileInmueble(
                      imageUrl: "",
                      isIcon: false,
                      inmuebleId: inmueble.id,
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inmueble.nombre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  inmueble.detalle ?? 'Sin detalles',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.hotel, size: 16),
                    const SizedBox(width: 4),
                    Text('${inmueble.numHabitacion} habitaciones'),
                    const SizedBox(width: 16),
                    const Icon(Icons.stairs, size: 16),
                    const SizedBox(width: 4),
                    Text('Piso ${inmueble.numPiso}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(CupertinoIcons.money_dollar_circle, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '\Bs${inmueble.precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: inmueble.isOcupado ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        inmueble.isOcupado ? 'Ocupado' : 'Disponible',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8.0, // gap between adjacent chips
                  runSpacing: 4.0, // gap between lines
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        _launchURL(dotenv.env['URL_CONTROL_CHAPA'] ?? '');
                      },
                      icon: const Icon(Icons.lock, color: Colors.blue),
                      label: const Text('Control Chapa'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _launchURL(dotenv.env['URL_CONTROL_LUCES'] ?? '');
                      },
                      icon: const Icon(Icons.lightbulb, color: Colors.amber),
                      label: const Text('Control Luces'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        provider.selectInmueble(inmueble);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => DetalleInmueblesScreen(
                                  isEditing: true,
                                  inmueble: inmueble,
                                ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _showDeleteConfirmationDialog(
                          context,
                          inmueble,
                          provider,
                        );
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        'Eliminar',
                        style: TextStyle(color: Colors.red),
                      ),
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

  Future<void> _launchURL(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL no configurada')),
      );
      return;
    }

    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir $url')),
      );
    }
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    InmuebleModel inmueble,
    InmuebleProvider provider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text(
              '¿Estás seguro de que deseas eliminar el inmueble "${inmueble.nombre}"?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await provider.deleteInmueble(inmueble.id);
                },
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
