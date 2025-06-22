import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/authenticated_provider.dart';

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
        title: const Text('Panel de Cliente'),
        actions: [
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
                        Text(
                          'Bienvenido, ${user?.name ?? "Cliente"}',
                          style: Theme.of(context).textTheme.headlineSmall,
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Funcionalidad en desarrollo: Pagos Pendientes'),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Funcionalidad en desarrollo: Historial de Pagos'),
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
                          // Navigate to make payment screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Funcionalidad en desarrollo: Realizar Pago'),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Funcionalidad en desarrollo: Contratos Activos'),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Funcionalidad en desarrollo: Historial de Contratos'),
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
