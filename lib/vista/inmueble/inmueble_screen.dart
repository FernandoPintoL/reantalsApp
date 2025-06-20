import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/inmueble_model.dart';
import '../../negocio/InmuebleNegocio.dart';
import '../../negocio/SessionNegocio.dart';
import '../../providers/inmueble_provider.dart';
import 'inmueble_card.dart';
import 'solicitud_alquiler_screen.dart';

class InmuebleScreen extends StatefulWidget {
  const InmuebleScreen({super.key});

  @override
  State<InmuebleScreen> createState() => _InmuebleScreenState();
}

class _InmuebleScreenState extends State<InmuebleScreen> {
  final InmuebleNegocio _inmuebleNegocio = InmuebleNegocio();
  final SessionNegocio _sessionNegocio = SessionNegocio();
  List<InmuebleModel> _inmuebles = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
  }

  /*Future<void> _loadInmuebles() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final inmuebles = await _inmuebleNegocio.getAllInmuebles();

      setState(() {
        _inmuebles = inmuebles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar los inmuebles: $e';
        _isLoading = false;
      });
    }
  }*/

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
        title: const Text('Propiedades para Alquiler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.login),
            onPressed: () => Navigator.of(context).pushNamed('/login'),
            tooltip: 'Iniciar Sesión',
          ),
        ],
      ),
      body:
          context.watch<InmuebleProvider>().isLoading
              ? const Center(child: CircularProgressIndicator())
              : context.watch<InmuebleProvider>().message != null
              ? Center(child: Text(context.watch<InmuebleProvider>().message ?? ''))
              : context.watch<InmuebleProvider>().inmuebles.isEmpty
              ? const Center(child: Text('No hay propiedades disponibles'))
              : RefreshIndicator(
                onRefresh: context.read().loadInmuebles,
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
