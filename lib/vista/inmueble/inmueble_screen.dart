import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:rentals/controllers_providers/authenticated_provider.dart';
import 'package:rentals/vista/components/Loading.dart';
import '../../models/inmueble_model.dart';
import '../../negocio/SessionNegocio.dart';
import '../../controllers_providers/blockchain_provider.dart';
import '../../controllers_providers/inmueble_provider.dart';
import '../components/message_widget.dart';
import 'inmueble_card.dart';
import 'solicitud_alquiler_screen.dart';

class InmuebleScreen extends StatefulWidget {
  const InmuebleScreen({super.key});

  @override
  State<InmuebleScreen> createState() => _InmuebleScreenState();
}

class _InmuebleScreenState extends State<InmuebleScreen> {
  final SessionNegocio _sessionNegocio = SessionNegocio();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadPageForUser() async {
    if (context.read<AuthenticatedProvider>().userActual != null) {
      // decidir si es usuario cliente o propietario
      if (context.read<AuthenticatedProvider>().userActual!.tipoUsuario ==
          'propietario') {
        // User is a property owner, navigate to property management screen
        Navigator.of(context).pushNamed('/homePropietario');
      } else {
        // User is a client, navigate to rental request screen
        Navigator.of(context).pushNamed('/homeCliente');
      }
    } else {
      // User is not logged in, navigate to login screen
      Navigator.of(context).pushNamed('/login');
    }
  }

  Future<void> _handleContractRequest(InmuebleModel inmueble) async {
    // Check if user is logged in
    final session = await _sessionNegocio.getSession();

    if (session == null) {
      // User is not logged in, navigate to login screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe iniciar sesión para solicitar un alquiler'),
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.of(context).pushNamed('/login');
    } else {
      // User is logged in, navigate to rental request screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SolicitudAlquilerScreen(inmueble: inmueble),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inmuebles Disponibles'),
        actions: [
          IconButton(
            icon:
                context.read<AuthenticatedProvider>().userActual != null
                    ? Icon(CupertinoIcons.person_alt_circle)
                    : Icon(Icons.login),
            onPressed: () => _loadPageForUser(),
            tooltip:
                context.read<AuthenticatedProvider>().userActual != null
                    ? 'Iniciar Sesión'
                    : 'Ver Perfil',
          ),
        ],
      ),
      body:
          context.watch<InmuebleProvider>().isLoading
              ? Loading(title: "Cargando pantalla principal")
              : context.watch<InmuebleProvider>().message != null && context.watch<InmuebleProvider>().messageType == MessageType.error || context.watch<InmuebleProvider>().messageType == MessageType.info
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: MessageWidget(
                    message: context.watch<InmuebleProvider>().message == null
                        ? 'No hay propiedades disponibles'
                        : context.watch<InmuebleProvider>().message!,
                    type: context.watch<InmuebleProvider>().messageType,
                ),
              ))
              : context.watch<InmuebleProvider>().inmuebles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No hay propiedades disponibles',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<InmuebleProvider>().loadInmuebles();
                        },
                        child: const Text('Intentar recargar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                onRefresh: context.read<InmuebleProvider>().loadInmuebles,
                child: ListView.builder(
                  itemCount: context.watch<InmuebleProvider>().inmuebles.length,
                  itemBuilder: (context, index) {
                    InmuebleModel inmueble =
                        context.watch<InmuebleProvider>().inmuebles[index];
                    return InmuebleCard(
                      inmueble: inmueble,
                      onContractRequest: () => _handleContractRequest(inmueble),
                    );
                  },
                ),
              ),
    );
  }
}
