import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/authenticated_provider.dart';
import 'inmuebles/inmuebles_screen.dart';
import 'inmuebles/detalle_inmuebles.dart';
import 'solicitudes/solicitudes_screen.dart';

class HomePropietarioScreen extends StatefulWidget {
  const HomePropietarioScreen({super.key});

  @override
  State<HomePropietarioScreen> createState() => _HomePropietarioScreenState();
}

class _HomePropietarioScreenState extends State<HomePropietarioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthenticatedProvider>().userActual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Propietario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Implement logout functionality
              Navigator.of(context).pushReplacementNamed('/');
            },
            tooltip: 'Cerrar Sesión',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Inmuebles'),
            Tab(icon: Icon(Icons.description), text: 'Contratos'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Pagos'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              // Inmuebles Tab
              _buildInmueblesTab(context, user),

              // Contratos Tab
              _buildContratosTab(context, user),

              // Pagos Tab
              _buildPagosTab(context, user),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action depends on current tab
          switch (_tabController.index) {
            case 0: // Inmuebles
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DetalleInmueblesScreen(
                    isEditing: false,
                  ),
                ),
              );
              break;
            case 1: // Contratos
              _showAddContratoDialog(context);
              break;
            case 2: // Pagos
              _showPaymentOptionsDialog(context);
              break;
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInmueblesTab(BuildContext context, dynamic user) {
    return SingleChildScrollView(
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
                    'Bienvenido, ${user?.name ?? "Propietario"}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gestiona tus inmuebles ofertados, contratos y pagos.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Mis Inmuebles',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Placeholder for inmuebles list
          Card(
            elevation: 4,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Inmuebles Publicados'),
                  subtitle: const Text('Gestiona tus inmuebles en oferta'),
                  leading: const Icon(Icons.apartment, color: Colors.blue),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InmueblesScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Añadir Nuevo Inmueble'),
                  subtitle: const Text('Publica un nuevo inmueble para alquiler'),
                  leading: const Icon(Icons.add_home, color: Colors.green),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DetalleInmueblesScreen(
                          isEditing: false,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContratosTab(BuildContext context, dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gestión de Contratos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 4,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Contratos Activos'),
                  subtitle: const Text('Gestiona tus contratos vigentes'),
                  leading: const Icon(Icons.description, color: Colors.green),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidad en desarrollo: Contratos Activos'),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Solicitudes de Alquiler'),
                  subtitle: const Text('Gestiona las solicitudes de alquiler y crea contratos'),
                  leading: const Icon(Icons.request_page, color: Colors.orange),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SolicitudesScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Crear Nuevo Contrato'),
                  subtitle: const Text('Establece un nuevo contrato con condicionales'),
                  leading: const Icon(Icons.add_chart, color: Colors.blue),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showAddContratoDialog(context),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Condicionales de Contratos'),
                  subtitle: const Text('Gestiona las cláusulas condicionales'),
                  leading: const Icon(Icons.rule, color: Colors.orange),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidad en desarrollo: Condicionales de Contratos'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Historial de Contratos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 4,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Contratos Finalizados'),
                  subtitle: const Text('Revisa tus contratos anteriores'),
                  leading: const Icon(Icons.history, color: Colors.grey),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidad en desarrollo: Contratos Finalizados'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagosTab(BuildContext context, dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gestión de Pagos Blockchain',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 4,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Pagos Recibidos'),
                  subtitle: const Text('Visualiza los pagos recibidos de tus inquilinos'),
                  leading: const Icon(Icons.payments, color: Colors.green),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidad en desarrollo: Pagos Recibidos'),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Pagos Pendientes'),
                  subtitle: const Text('Revisa los pagos pendientes y envía recordatorios'),
                  leading: const Icon(Icons.payment, color: Colors.red),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidad en desarrollo: Pagos Pendientes'),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Condicionales Automáticas'),
                  subtitle: const Text('Gestiona las acciones automáticas por retrasos'),
                  leading: const Icon(Icons.auto_awesome, color: Colors.purple),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidad en desarrollo: Condicionales Automáticas'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Configuración de Blockchain',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 4,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Configurar Wallet'),
                  subtitle: const Text('Configura tu billetera para recibir pagos'),
                  leading: const Icon(Icons.account_balance_wallet, color: Colors.amber),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidad en desarrollo: Configurar Wallet'),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Historial de Transacciones'),
                  subtitle: const Text('Revisa todas las transacciones realizadas'),
                  leading: const Icon(Icons.history, color: Colors.blue),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidad en desarrollo: Historial de Transacciones'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Navigation to InmueblesScreen and DetalleInmueblesScreen is now handled directly in the UI

  void _showAddContratoDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad en desarrollo: Crear Contrato con Condicionales'),
      ),
    );
  }

  void _showPaymentOptionsDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad en desarrollo: Opciones de Pago Blockchain'),
      ),
    );
  }
}
