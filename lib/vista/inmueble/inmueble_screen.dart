import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentals/controllers_providers/authenticated_provider.dart';
import 'package:rentals/vista/components/Loading.dart';
import '../../models/inmueble_model.dart';
import '../../negocio/InmuebleNegocio.dart';
import '../../negocio/SessionNegocio.dart';
import '../../controllers_providers/blockchain_provider.dart';
import '../../controllers_providers/inmueble_provider.dart';
import 'inmueble_card.dart';
import 'solicitud_alquiler_screen.dart';

class InmuebleScreen extends StatefulWidget {
  final bool initializeBlockchain;

  const InmuebleScreen({super.key, this.initializeBlockchain = false});

  @override
  State<InmuebleScreen> createState() => _InmuebleScreenState();
}

class _InmuebleScreenState extends State<InmuebleScreen> {
  final SessionNegocio _sessionNegocio = SessionNegocio();

  @override
  void initState() {
    super.initState();
    if (widget.initializeBlockchain) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final blockchainProvider = Provider.of<BlockchainProvider>(context, listen: false);

        // Initialize with test network values
        await blockchainProvider.initialize(
          rpcUrl: 'https://sepolia.infura.io/v3/your-infura-key', // Replace with actual Infura key
          privateKey: '0x0000000000000000000000000000000000000000000000000000000000000000', // Replace with actual private key
          chainId: 11155111, // Sepolia testnet
        );
      });
    }
  }

  Future<void> _loadPageForUser() async {
    if(context.read<AuthenticatedProvider>().userActual != null) {
      // decidir si es usuario cliente o propietario
      if(context.read<AuthenticatedProvider>().userActual!.tipoUsuario == 'propietario') {
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
          builder: (context) => SolicitudAlquilerScreen(
            inmueble: inmueble,
          ),
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
            icon: context.read<AuthenticatedProvider>().userActual != null ? Icon(CupertinoIcons.person_alt_circle) : Icon(Icons.login),
            onPressed: () => _loadPageForUser(),
            tooltip: context.read<AuthenticatedProvider>().userActual != null ? 'Iniciar Sesión' : 'Ver Perfil',
          ),
        ],
      ),
      body:
          context.watch<InmuebleProvider>().isLoading
              ? Loading(title: "Cargando pantalla principal",)
              : context.watch<InmuebleProvider>().message != null
              ? Center(child: Text(context.watch<InmuebleProvider>().message ?? ''))
              : context.watch<InmuebleProvider>().inmuebles.isEmpty
              ? const Center(child: Text('No hay propiedades disponibles'))
              : RefreshIndicator(
                onRefresh: context.read<InmuebleProvider>().loadInmuebles,
                child: ListView.builder(
                  itemCount: context.watch<InmuebleProvider>().inmuebles.length,
                  itemBuilder: (context, index) {
                    InmuebleModel inmueble = context.watch<InmuebleProvider>().inmuebles[index];
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
