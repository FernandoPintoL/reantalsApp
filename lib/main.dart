import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'controllers_providers/authenticated_provider.dart';
import 'controllers_providers/blockchain_provider.dart';
import 'controllers_providers/contrato_provider.dart';
import 'controllers_providers/inmueble_provider.dart';
import 'controllers_providers/pago_provider.dart';
import 'controllers_providers/solicitud_alquiler_provider.dart';
import 'services/ApiService.dart';
import 'services/UrlConfigProvider.dart';
import 'vista/auth/login_screen.dart';
import 'vista/auth/register_screen.dart';
import 'vista/home_cliente/home_cliente_screen.dart';
import 'vista/home_propietario/home_propietario_screen.dart';
import 'vista/inmueble/inmueble_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // Create and initialize the UrlConfigProvider
  final urlConfigProvider = UrlConfigProvider();

  // Set it as the shared provider for ApiService
  ApiService.setSharedUrlConfigProvider(urlConfigProvider);

  runApp(MyApp(urlConfigProvider: urlConfigProvider));
}

class MyApp extends StatefulWidget {
  final UrlConfigProvider? urlConfigProvider;

  const MyApp({super.key, this.urlConfigProvider});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Use the provided UrlConfigProvider if available, otherwise create a new one
        ChangeNotifierProvider<UrlConfigProvider>.value(
          value: widget.urlConfigProvider ?? UrlConfigProvider(),
        ),
        ChangeNotifierProvider(create: (context) => AuthenticatedProvider()),
        ChangeNotifierProvider(create: (context) => InmuebleProvider()),
        ChangeNotifierProvider(create: (context) => SolicitudAlquilerProvider()),
        ChangeNotifierProvider(create: (context) => BlockchainProvider()),
        ChangeNotifierProvider(create: (context) => ContratoProvider()),
        ChangeNotifierProvider(create: (context) => PagoProvider()),
      ],
      child: MaterialApp(
        title: dotenv.env['PROJECT_NAME'] ?? 'Alquileres',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
          visualDensity: VisualDensity.adaptivePlatformDensity,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => InmuebleScreen(initializeBlockchain: true),
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/home': (context) => InmuebleScreen(),
          '/homePropietario': (context) => HomePropietarioScreen(),
          '/homeCliente': (context) => HomeClienteScreen(),
        },
      ),
    );
  }
}
