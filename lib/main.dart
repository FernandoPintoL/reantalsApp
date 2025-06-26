import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'controllers_providers/authenticated_provider.dart';
import 'controllers_providers/blockchain_provider.dart';
import 'controllers_providers/contrato_provider.dart';
import 'controllers_providers/inmueble_provider.dart';
import 'controllers_providers/pago_provider.dart';
import 'controllers_providers/solicitud_alquiler_provider.dart';
import 'controllers_providers/user_global_provider.dart';
import 'services/ApiService.dart';
import 'services/UrlConfigProvider.dart';
import 'services/notification_service.dart';
import 'services/socket_service.dart';
import 'services/websocket_admin_service.dart';
import 'vista/auth/login_screen.dart';
import 'vista/auth/register_screen.dart';
import 'vista/auth/edit_profile_screen.dart';
import 'vista/home_cliente/home_cliente_screen.dart';
import 'vista/home_propietario/home_propietario_screen.dart';
import 'vista/inmueble/inmueble_screen.dart';
import 'vista/admin/websocket_admin_screen.dart';
import 'vista/notifications/notification_center_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize blockchain provider
  await BlockchainProvider.instance.initializeFromEnv();

  // Initialize notification service
  /*final notificationService = NotificationService();
  await notificationService.initialize();*/

  // Create and initialize the UrlConfigProvider first
  final urlConfigProvider = UrlConfigProvider();

  // Set it as the shared provider for ApiService
  ApiService.setSharedUrlConfigProvider(urlConfigProvider);

  // Initialize socket service after UrlConfigProvider is created
  final socketService = SocketService();
  socketService.initialize();

  // Initialize websocket admin service
  final websocketAdminService = WebSocketAdminService(socketService);

  runApp(MyApp(
    urlConfigProvider: urlConfigProvider,
    // notificationService: notificationService,
    socketService: socketService,
    websocketAdminService: websocketAdminService,
  ));
}

class MyApp extends StatefulWidget {
  final UrlConfigProvider? urlConfigProvider;
  // final NotificationService notificationService;
  final SocketService socketService;
  final WebSocketAdminService websocketAdminService;

  const MyApp({
    super.key, 
    this.urlConfigProvider,
    // required this.notificationService,
    required this.socketService,
    required this.websocketAdminService,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    widget.socketService.dispose();
    widget.websocketAdminService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Use the provided UrlConfigProvider if available, otherwise create a new one
        ChangeNotifierProvider<UrlConfigProvider>.value(
          value: widget.urlConfigProvider ?? UrlConfigProvider(),
        ),
        // Global user provider (singleton)
        ChangeNotifierProvider<UserGlobalProvider>.value(
          value: UserGlobalProvider(),
        ),
        // Provide socket service
        Provider<SocketService>.value(
          value: widget.socketService,
        ),
        // Provide websocket admin service
        Provider<WebSocketAdminService>.value(
          value: widget.websocketAdminService,
        ),
        // Provide notification service
        Provider<NotificationService>(create: (context) => NotificationService()),
        // BlockchainProvider is already provided as a singleton below
        ChangeNotifierProvider(create: (context) => AuthenticatedProvider()),
        ChangeNotifierProvider(create: (context) => InmuebleProvider()),
        ChangeNotifierProvider(create: (context) => SolicitudAlquilerProvider()),
        // Use the singleton instance of BlockchainProvider
        ChangeNotifierProvider<BlockchainProvider>.value(value: BlockchainProvider.instance),
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
          '/': (context) => const InmuebleScreen(),
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/home': (context) => const InmuebleScreen(),
          '/homePropietario': (context) => HomePropietarioScreen(),
          '/homeCliente': (context) => HomeClienteScreen(),
          '/editProfile': (context) => EditProfileScreen(),
          '/websocketAdmin': (context) => WebSocketAdminScreen(),
          '/notifications': (context) => NotificationCenterScreen(),
        },
      ),
    );
  }
}
