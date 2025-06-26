import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers_providers/authenticated_provider.dart';
import '../../controllers_providers/user_global_provider.dart';
import '../../controllers_providers/blockchain_provider.dart';
import '../../models/user_model.dart';
import '../components/message_widget.dart';
import '../../widgets/blockchain_websocket_drawer.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernickController = TextEditingController();
  final _numIdController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _walletAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load user data from global provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserGlobalProvider>(context, listen: false);
      final user = userProvider.currentUser;
      if (user != null) {
        _nameController.text = user.name;
        _emailController.text = user.email;
        _usernickController.text = user.usernick;
        _numIdController.text = user.numId;
        _telefonoController.text = user.telefono;
        _direccionController.text = user.direccion;
        _walletAddressController.text = user.walletAddress ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernickController.dispose();
    _numIdController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _walletAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticatedProvider>(context);
    final userProvider = Provider.of<UserGlobalProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Ver estado de servicios',
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: const BlockchainWebSocketDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (authProvider.message != null)
                MessageWidget(
                  message: authProvider.message!,
                  type: authProvider.messageType,
                ),
              const SizedBox(height: 16),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su correo electrónico';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Por favor ingrese un correo electrónico válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Username field
              TextFormField(
                controller: _usernickController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de usuario',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su nombre de usuario';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ID Number field
              TextFormField(
                controller: _numIdController,
                decoration: const InputDecoration(
                  labelText: 'Número de identificación',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su número de identificación';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone field
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su número de teléfono';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address field
              if(userProvider.currentUser?.tipoUsuario != 'cliente')
                TextFormField(
                  controller: _direccionController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 16),

              // Wallet Address field (read-only)
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Dirección de Billetera Blockchain',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _walletAddressController.text.isEmpty 
                            ? 'No disponible - Conecte a la blockchain primero'
                            : _walletAddressController.text,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: _walletAddressController.text.isEmpty ? Colors.grey : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Esta dirección se genera automáticamente al conectarse a la blockchain y no puede ser modificada manualmente.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                onPressed: authProvider.isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          // Get current user
                          final currentUser = userProvider.currentUser;
                          if (currentUser != null) {
                            // Update user data
                            final updatedUser = UserModel(
                              id: currentUser.id,
                              name: _nameController.text,
                              email: _emailController.text,
                              usernick: _usernickController.text,
                              numId: _numIdController.text,
                              telefono: _telefonoController.text,
                              direccion: _direccionController.text,
                              walletAddress: _walletAddressController.text.isEmpty
                                  ? null
                                  : _walletAddressController.text,
                              tipoUsuario: currentUser.tipoUsuario,
                              tipoCliente: currentUser.tipoCliente,
                              photoPath: currentUser.photoPath,
                              createdAt: currentUser.createdAt,
                              updatedAt: currentUser.updatedAt,
                            );

                            // Call update method (to be implemented)
                            await authProvider.updateUserProfile(updatedUser);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: authProvider.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
