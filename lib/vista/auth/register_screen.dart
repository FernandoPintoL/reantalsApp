import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentals/providers/authenticated_provider.dart';
import 'package:rentals/vista/components/app_icon_widget.dart';

import '../components/message_widget.dart';
import '../interfaces/authenticated_screen_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> implements AuthenticatedScreenState {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _direccionController = TextEditingController();
  bool _isOwner = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  // Temporarily bypassing actual registration
  Future<void> _register() async {
    await context.read<AuthenticatedProvider>().createUser(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade300,
              Colors.blue.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: context.read<AuthenticatedProvider>().formCreateKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIconWidget(),
                        const SizedBox(height: 20),
                        const Text(
                          'Crear cuenta',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.watch<AuthenticatedProvider>().isPropietario ? 'Registrar como Propietario' : 'Registrar como Cliente',
                          style: TextStyle(
                            color: context.watch<AuthenticatedProvider>().isPropietario ? Colors.blue.shade800 : Colors.green.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 30),
                        if (context.watch<AuthenticatedProvider>().message != null)
                          /*Container(
                            padding: const EdgeInsets.all(8.0),
                            margin: const EdgeInsets.only(bottom: 16.0),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              context.watch<AuthenticatedProvider>().message!,
                              style: TextStyle(color: Colors.red.shade800),
                            ),
                          ),*/
                          MessageWidget(
                            message: context.watch<AuthenticatedProvider>().message!,
                            type: context.watch<AuthenticatedProvider>().messageType,
                          ),
                        const SizedBox(height: 8),
                        // Nombre Completo
                        TextFormField(
                          controller: context.watch<AuthenticatedProvider>().nameController,
                          focusNode: context.watch<AuthenticatedProvider>().nameFocusNode,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nombre Completo',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Regístrate para comenzar';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Email
                        TextFormField(
                          controller: context.watch<AuthenticatedProvider>().emailController,
                          focusNode: context.watch<AuthenticatedProvider>().emailFocusNode,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su correo electrónico';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Por favor, introduzca un correo electrónico válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // usernick
                        TextFormField(
                          controller: context.watch<AuthenticatedProvider>().usernickController,
                          focusNode: context.watch<AuthenticatedProvider>().usernickFocusNode,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Usernick',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su usernick';
                            }
                            return null;
                          },
                        ),
                        // Número de Identificación
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: context.watch<AuthenticatedProvider>().numIdController,
                          focusNode: context.watch<AuthenticatedProvider>().numIdFocusNode,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Número de Identificación',
                            prefixIcon: Icon(Icons.credit_card),
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
                        // Número de Teléfono (opcional)
                        TextFormField(
                          controller: context.watch<AuthenticatedProvider>().phoneController,
                          focusNode: context.watch<AuthenticatedProvider>().phoneFocusNode,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Número de teléfono',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty && !RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
                              return 'Por favor, introduzca un número de teléfono válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Contraseña
                        TextFormField(
                          controller: context.watch<AuthenticatedProvider>().passwordController,
                          focusNode: context.watch<AuthenticatedProvider>().passwordFocusNode,
                          textInputAction: TextInputAction.next,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Confirmar Contraseña
                        TextFormField(
                          controller: context.watch<AuthenticatedProvider>().confirmPasswordController,
                          focusNode: context.watch<AuthenticatedProvider>().confirmPasswordFocusNode,
                          textInputAction: TextInputAction.next,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        if( context.watch<AuthenticatedProvider>().isPropietario )
                          // Dirección (opcional)
                          TextFormField(
                            controller: context.watch<AuthenticatedProvider>().direccionController,
                            decoration: const InputDecoration(
                              labelText: 'Direccion',
                              prefixIcon: Icon(Icons.location_on),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Switch para propietario
                        SwitchListTile(
                          title: const Text('Quiero alquilar propiedades'),
                          subtitle: const Text('Registrarse como propietario'),
                          value: context.read<AuthenticatedProvider>().isPropietario,
                          activeColor: Colors.blue,
                          onChanged: (value) {
                            /*setState(() {
                              _isOwner = value;
                            });*/
                            context.read<AuthenticatedProvider>().isPropietario = value;
                          },
                        ),
                        const SizedBox(height: 24),
                        // Botón de registro
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: context.watch<AuthenticatedProvider>().isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: context.watch<AuthenticatedProvider>().isLoading
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  )
                                : Text(
                              context.watch<AuthenticatedProvider>().isPropietario ? 'Registrarme como Propietario' : 'Registrarme como Cliente',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Ya tienes una cuenta?'),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacementNamed('/login');
                              },
                              child: const Text('Iniciar sesión'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Future<void> navigateToHomeCliente() {
    // TODO: implement navigateToHomeCliente
    throw UnimplementedError();
  }

  @override
  Future<void> navigateToHomePropietario() {
    // TODO: implement navigateToHomePropietario
    throw UnimplementedError();
  }
}
