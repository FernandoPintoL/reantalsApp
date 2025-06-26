import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers_providers/authenticated_provider.dart';
import '../../widgets/notification_badge.dart';
import 'pagos/pagos_pendientes_screen.dart';
import 'pagos/historial_pagos_screen.dart';
import 'contratos/contratos_cliente_screen.dart';
import 'contratos/historial_contratos_screen.dart';
import 'solicitudes/solicitudes_screen.dart';
import '../blockchain/blockchain_control_screen.dart';

class HomeClienteScreen extends StatefulWidget {
  const HomeClienteScreen({super.key});

  @override
  State<HomeClienteScreen> createState() => _HomeClienteScreenState();
}

class _HomeClienteScreenState extends State<HomeClienteScreen> {
  bool _isLoading = false;

  Future<void> _cerrarSession() async {
    setState(() {
      _isLoading = true;
    });
    bool result = await context.read<AuthenticatedProvider>().logout();
    if (!result) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cerrar sesión')),
      );
      return;
    }
    setState(() {
      _isLoading = false;
    });
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthenticatedProvider>().userActual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Cliente - Blockchain'),
        actions: [
          const NotificationBadge(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Implement logout functionality
              _cerrarSession();
            },
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if(context.watch<AuthenticatedProvider>().userActual != null)
                          Text(
                            'Bienvenido, ${context.watch<AuthenticatedProvider>().userActual!.name ?? "Cliente"}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          )
                        else
                          const Text(
                            'Bienvenido, Cliente',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Gestiona tus pagos mensuales y revisa el estado de tus contratos.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Payments section
                Text(
                  'Gestión de Pagos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // Payments list
                Card(
                  elevation: 4,
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Pagos Pendientes'),
                        subtitle: const Text('Visualiza y gestiona tus pagos pendientes'),
                        leading: const Icon(Icons.payment, color: Colors.red),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigate to pending payments screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PagosPendientesScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Historial de Pagos'),
                        subtitle: const Text('Revisa tus pagos anteriores'),
                        leading: const Icon(Icons.history, color: Colors.blue),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigate to payment history screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HistorialPagosScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Realizar Pago'),
                        subtitle: const Text('Paga tu mensualidad mediante blockchain'),
                        leading: const Icon(Icons.account_balance_wallet, color: Colors.green),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigate to pending payments screen to select a payment to make
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PagosPendientesScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Contracts section
                Text(
                  'Mis Contratos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                Card(
                  elevation: 4,
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Contratos Activos'),
                        subtitle: const Text('Visualiza tus contratos actuales'),
                        leading: const Icon(Icons.description, color: Colors.green),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigate to active contracts screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ContratosClienteScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Historial de Contratos'),
                        subtitle: const Text('Revisa tus contratos anteriores'),
                        leading: const Icon(Icons.history, color: Colors.blue),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigate to contract history screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HistorialContratosScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Solicitudes section
                Text(
                  'Mis Solicitudes de Alquiler',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                Card(
                  elevation: 4,
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Mis Solicitudes'),
                        subtitle: const Text('Visualiza todas tus solicitudes de alquiler'),
                        leading: const Icon(Icons.list_alt, color: Colors.orange),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigate to rental requests screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SolicitudesScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Profile section
                Text(
                  'Mi Perfil',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                Card(
                  elevation: 4,
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Editar Perfil'),
                        subtitle: const Text('Actualiza tu información personal'),
                        leading: const Icon(Icons.person, color: Colors.orange),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigate to edit profile screen
                          Navigator.pushNamed(context, '/editProfile');
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Blockchain section
                Text(
                  'Blockchain',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                Card(
                  elevation: 4,
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Control Blockchain'),
                        subtitle: const Text('Monitorea tus transacciones en la blockchain'),
                        leading: const Icon(Icons.account_tree, color: Colors.purple),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigate to blockchain control screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BlockchainControlScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
