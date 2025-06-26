import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentals/controllers_providers/authenticated_provider.dart';
import '../models/condicional_model.dart';
import '../models/contrato_model.dart';
import '../models/inmueble_model.dart';
import '../models/response_model.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';
import '../models/solicitud_alquiler_model.dart';
import '../negocio/AuthenticatedNegocio.dart';
import '../negocio/ContratoNegocio.dart';
import '../negocio/InmuebleNegocio.dart';
import '../negocio/SessionNegocio.dart';
import '../negocio/SolicitudAlquilerNegocio.dart';
import '../negocio/UserNegocio.dart';
import '../services/notification_service.dart';
import '../services/socket_service.dart';
import '../vista/components/message_widget.dart';
import 'blockchain_provider.dart';
import 'user_global_provider.dart';

class ContratoProvider extends ChangeNotifier {
  final BlockchainProvider _blockchainProvider = BlockchainProvider.instance;
  final ContratoNegocio _contratoNegocio = ContratoNegocio();
  final SolicitudAlquilerNegocio _solicitudNegocio = SolicitudAlquilerNegocio();
  final AuthenticatedNegocio _authenticatedNegocio = AuthenticatedNegocio();
  final UserNegocio _userNegocio = UserNegocio();
  final InmuebleNegocio _inmuebleNegocio = InmuebleNegocio();
  final UserGlobalProvider _userGlobalProvider = UserGlobalProvider();

  // Services for notifications
  late SocketService _socketService;
  late NotificationService _notificationService;
  final BuildContext? _context;

  List<ContratoModel> _contratos = [];
  List<ContratoModel> _contratosPendientesCliente = [];
  List<ContratoModel> _contratosPendientesPropietario = [];
  List<ContratoModel> _contratosActivosCliente = [];
  List<ContratoModel> _contratosActivosPropietario = [];
  List<CondicionalModel> _condicionales = [];
  ContratoModel? _selectedContrato;
  bool _isLoading = false;
  String? _message;
  UserModel? _currentUser;
  MessageType _messageType = MessageType.info;

  ContratoProvider({BuildContext? context}) 
      : _context = context {
    // Get the current user from the global provider
    loadCurrentUser();

    // Listen for changes to the global user state
    _userGlobalProvider.addListener(_onUserChanged);

    // Initialize services if context is provided
    if (_context != null) {
      _socketService = Provider.of<SocketService>(_context, listen: false);
      _notificationService = Provider.of<NotificationService>(_context, listen: false);
    }
    if (condicionales.isEmpty) {
      condicionales = [
        CondicionalModel(
          id: 1,
          descripcion: 'Retraso en el pago mensual',
          tipoCondicion: 'retraso_pago',
          accion: 'multa',
          parametros: {'dias_retraso': 5, 'porcentaje_multa': 10},
        ),
        CondicionalModel(
          id: 2,
          descripcion: 'Daños a la propiedad',
          tipoCondicion: 'daños',
          accion: 'reparacion',
          parametros: {'responsable': 'inquilino'},
        ),
        CondicionalModel(
          id: 3,
          descripcion: 'Autenticación de acceso mediante chapas electronicas',
          tipoCondicion: 'acceso',
          accion: 'seguridad',
          parametros: {'responsable': 'propietario'},
        ),
      ];
    }
  }

  // Method to initialize services if not done in constructor
  void initializeServices(BuildContext context) {
    _socketService = Provider.of<SocketService>(context, listen: false);
    _notificationService = Provider.of<NotificationService>(context, listen: false);
  }

  // Cleanup listener when provider is disposed
  @override
  void dispose() {
    _userGlobalProvider.removeListener(_onUserChanged);
    super.dispose();
  }

  // Called when the global user state changes
  void _onUserChanged() {
    currentUser = _userGlobalProvider.currentUser;
  }

  Future<void> loadCurrentUser() async {
    try {
      isLoading = true;

      // First try to get the user from the global provider
      currentUser = _userGlobalProvider.currentUser;

      // If not available in global provider, try to load from session
      if (currentUser == null) {
        currentUser = await _authenticatedNegocio.getUserSession();

        // If we found a user in the session, update the global provider
        if (currentUser != null) {
          _userGlobalProvider.updateUser(currentUser);
        }
      }

      if (currentUser == null) {
        messageType = MessageType.info;
        message = 'Usuario no encontrado, se ha creado un usuario temporal';
      } else {
        messageType = MessageType.success;
        message = 'Usuario actual cargado exitosamente';
      }
    } catch (e) {
      messageType = MessageType.error;
      message = 'Error al cargar el usuario actual: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<bool> createContrato(ContratoModel contrato, {BuildContext? context}) async {
    try {
      // Initialize services if context is provided and not already initialized
      if (context != null && !_isServicesInitialized()) {
        print('Initializing services in createContrato');
        initializeServices(context);
      }

      isLoading = true;
      if (currentUser == null) {
        await loadCurrentUser();
        if (currentUser == null) {
          message = 'No se pudo cargar el usuario actual';
          isLoading = false;
          return false;
        }
      }

      ResponseModel response = await _contratoNegocio.createContrato(contrato);
      print('Response from createContrato: ${response.toJson()}');
      if (response.isSuccess && response.data != null) {
        selectedContrato = ContratoModel.fromMap(response.data);
        message = 'Contrato creado exitosamente';

        // If this contract is associated with a solicitud, update its status
        if (contrato.solicitudId != null) {
          ResponseModel _res = await _solicitudNegocio.updateSolicitudEstado(contrato.solicitudId!, 'contrato_generado');
          print('Response from updateSolicitudEstado: ${_res.toJson()}');
        }
        ResponseModel resCli = await _authenticatedNegocio.getUser(contrato.userId);
        UserModel? cliente = UserModel.mapToModel(resCli.data);
        InmuebleModel? inmueble = await _inmuebleNegocio.getInmuebleById(contrato.inmuebleId);
        ResponseModel resProp = await _authenticatedNegocio.getUser(inmueble!.userId);
        UserModel? propietario = UserModel.mapToModel(resProp.data);



        // Check if blockchain is initialized, if not, initialize it
        if (!_blockchainProvider.isInitialized) {
          print('Blockchain no inicializado, inicializando antes de crear contrato...');
          try {
            bool initSuccess = await _blockchainProvider.ensureInitialized();
            if (!initSuccess) {
              print('Error al inicializar el servicio blockchain');
              message = 'No se pudo inicializar el servicio blockchain';
              // Podrías querer registrar el error en un servicio de análisis
            } else {
              print('Servicio blockchain inicializado correctamente');
            }
          } catch (e) {
            print('Excepción durante la inicialización blockchain: $e');
            message = 'Error en la inicialización blockchain: ${e.toString()}';
          }
        }

        // Create contract on blockchain
        final blockchainResult = await _blockchainProvider.createRentalContract(
          selectedContrato!,
          propietario,
          cliente,
        );
        print('Blockchain result: $blockchainResult');

        if (blockchainResult != null) {
          message = '$message y registrado en blockchain';

          // Update contract with blockchain data
          if (blockchainResult.containsKey('txHash')) {
            selectedContrato!.blockchainTxHash = blockchainResult['txHash'];
          }

          if (blockchainResult.containsKey('contractAddress') && blockchainResult['contractAddress']!.isNotEmpty) {
            selectedContrato!.blockchainAddress = blockchainResult['contractAddress'];
            // Update contract in database with blockchain address and transaction hash
            await _contratoNegocio.updateContratoBlockchain(
                selectedContrato!.id,
                blockchainResult['contractAddress']!,
                blockchainTxHash: blockchainResult['txHash']
            );
          }
        }
        // Create contract on blockchain if both users have wallet addresses
        /*if (_blockchainProvider.isInitialized) {
          try {

          } catch (blockchainError) {
            // Don't fail the entire operation if blockchain fails
            print('Error creating contract on blockchain: $blockchainError');
          }
        }*/


        // Send notification via WebSocket if services are initialized
        if (_isServicesInitialized()) {
          try {
            // Send WebSocket notification
            _socketService.emitContractGenerated(
              solicitudId: contrato.solicitudId ?? 0,
              contratoId: selectedContrato!.id,
              propertyName: contrato.inmueble!.nombre,
              clientId: contrato.cliente!.id,
              propietarioId: contrato.inmueble!.userId,
            );

            // Show local notification
            _notificationService.showContractGeneratedNotification(
              solicitudId: contrato.solicitudId ?? 0,
              propertyName: contrato.inmueble!.nombre,
            );

            print('Contract generation notification sent');
          } catch (notificationError) {
            print('Error sending contract generation notification: $notificationError');
          }
        }

        await loadContratosByPropietarioId(); // Refresh the list
        isLoading = false;
        return true;
      } else {
        message = response.messageError ?? 'Error al crear el contrato';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al crear el contrato: $e';
      isLoading = false;
      return false;
    }
  }

  // Helper method to check if services are initialized
  bool _isServicesInitialized() {
    try {
      // Check if socket and notification services are initialized
      bool servicesInitialized = _socketService != null && _notificationService != null;

      // Check if blockchain is initialized, if not, try to initialize it
      if (!_blockchainProvider.isInitialized) {
        print('Blockchain not initialized, attempting to initialize...');
        // We don't await here because this method returns a bool, not a Future
        // The initialization will happen asynchronously
        _blockchainProvider.ensureInitialized();
      }

      return servicesInitialized && _blockchainProvider.isInitialized;
    } catch (e) {
      print('Error checking services initialization: $e');
      return false;
    }
  }

  Future<bool> createContratoFromSolicitud(
    SolicitudAlquilerModel solicitud, {
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required double monto,
    String? detalle,
    List<CondicionalModel> condicionales = const [],
    BuildContext? context,
  }) async {
    if (currentUser == null) {
      await loadCurrentUser();
      if (currentUser == null) {
        message = 'No se pudo cargar el usuario actual';
        return false;
      }
    }

    // Create a new contract from the solicitud
    final contrato = ContratoModel(
      inmuebleId: solicitud.inmuebleId,
      userId: solicitud.userId,
      solicitudId: solicitud.id,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      monto: monto,
      detalle: detalle,
      estado: 'pendiente',
      condicionales: condicionales,
      clienteAprobado: false,
      solicitud: solicitud,
      inmueble: solicitud.inmueble,
      cliente: solicitud.cliente,
    );

    return await createContrato(contrato, context: context);
  }

  Future<void> loadContratosByClienteId() async {
    if (currentUser == null) {
      await loadCurrentUser();
      if (currentUser == null) {
        message = 'No se pudo cargar el usuario actual';
        return;
      }
    }
    try {
      isLoading = true;
      ResponseModel response = await _contratoNegocio.getContratosByClienteId(currentUser!.id);
      if (response.isSuccess && response.data != null) {
        contratos = ContratoModel.fromJsonList(response.data);
        message = null; // Reset message on successful load
      } else {
        message = response.messageError ?? 'No se encontraron contratos para este usuario';
      }
    } catch (e) {
      message = 'Error al cargar los contratos del usuario: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadContratosByPropietarioId() async {
    if (currentUser == null) {
      await loadCurrentUser();
      if (currentUser == null) {
        message = 'No se pudo cargar el usuario actual';
        return;
      }
    }
    try {
      isLoading = true;
      ResponseModel response = await _contratoNegocio.getContratosByPropietarioId(currentUser!.id);

      if (response.isSuccess && response.data != null) {
        contratos = ContratoModel.fromJsonList(response.data);
        message = null; // Reset message on successful load
      } else {
        message = response.messageError ?? 'No se encontraron contratos para este propietario';
      }
    } catch (e) {
      message = 'Error al cargar los contratos del propietario: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadContratoById(int id) async {
    try {
      isLoading = true;
      ResponseModel response = await _contratoNegocio.getContratoById(id);

      if (response.isSuccess && response.data != null) {
        selectedContrato = ContratoModel.fromMap(response.data);
        message = null; // Reset message on successful load
      } else {
        message = response.messageError ?? 'No se encontró el contrato';
      }
    } catch (e) {
      message = 'Error al cargar el contrato: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<bool> updateContratoEstado(int id, String estado) async {
    try {
      isLoading = true;
      ResponseModel response = await _contratoNegocio.updateContratoEstado(id, estado);
      if (response.isSuccess) {
        message = 'Estado del contrato actualizado exitosamente';
        // Refresh the list based on user type
        if (currentUser?.tipoUsuario == 'propietario') {
          await loadContratosByPropietarioId();
        } else {
          await loadContratosByClienteId();
        }
        isLoading = false;
        return true;
      } else {
        message = response.messageError ?? 'Error al actualizar el estado del contrato';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al actualizar el estado del contrato: $e';
      isLoading = false;
      return false;
    }
  }

  Future<bool> updateContratoClienteAprobado(int id, bool clienteAprobado, {BuildContext? context}) async {
    // Initialize services if context is provided and not already initialized
    if (context != null && !_isServicesInitialized()) {
      initializeServices(context);
    }

    try {
      isLoading = true;
      ResponseModel response = await _contratoNegocio.updateContratoClienteAprobado(id, clienteAprobado);

      if (response.isSuccess) {
        message = clienteAprobado 
            ? 'Contrato aprobado exitosamente' 
            : 'Contrato rechazado exitosamente';

        // Update the contract status based on approval
        if (clienteAprobado) {
          await _contratoNegocio.updateContratoEstado(id, 'aprobado');

          // Check if blockchain is initialized, if not, initialize it
          if (!_blockchainProvider.isInitialized) {
            print('Blockchain not initialized, initializing before approving contract...');
            bool initSuccess = await _blockchainProvider.ensureInitialized();
            if (!initSuccess) {
              print('Failed to initialize blockchain service');
              message = '$message (No se pudo inicializar el servicio blockchain)';
              // Continue with contract approval even if blockchain initialization fails
            } else {
              print('Blockchain service initialized successfully');
            }
          }

          // Approve contract on blockchain
          try {
            final blockchainSuccess = await _blockchainProvider.approveContract(id);
            if (blockchainSuccess != null) {
              message = '$message y actualizado en blockchain';
            }
          } catch (blockchainError) {
            // Don't fail the entire operation if blockchain fails
            print('Error approving contract on blockchain: $blockchainError');
          }

          // Get the contract to send notification
          ContratoModel? contrato;
          for (var c in contratos) {
            if (c.id == id) {
              contrato = c;
              break;
            }
          }

          // Send notification via WebSocket if services are initialized and we have the contract data
          if (_isServicesInitialized() && contrato != null && contrato.inmueble != null && contrato.cliente != null) {
            try {
              // Send WebSocket notification
              _socketService.emitRequestStatusChanged(
                solicitudId: contrato.solicitudId ?? 0,
                propertyName: contrato.inmueble!.nombre,
                status: 'contrato_aprobado',
                clientId: contrato.cliente!.id,
                propietarioId: contrato.inmueble!.userId,
              );

              // Show local notification
              _notificationService.showNotification(
                id: id,
                title: 'Contrato Aprobado',
                body: 'El contrato para la propiedad ${contrato.inmueble!.nombre} ha sido aprobado',
                payload: 'contract_approved_$id',
              );

              print('Contract approval notification sent');
            } catch (notificationError) {
              print('Error sending contract approval notification: $notificationError');
            }
          }
        } else {
          await _contratoNegocio.updateContratoEstado(id, 'rechazado');

          // Get the contract to send notification
          ContratoModel? contrato;
          for (var c in contratos) {
            if (c.id == id) {
              contrato = c;
              break;
            }
          }

          // Send notification via WebSocket if services are initialized and we have the contract data
          if (_isServicesInitialized() && contrato != null && contrato.inmueble != null && contrato.cliente != null) {
            try {
              // Send WebSocket notification
              _socketService.emitRequestStatusChanged(
                solicitudId: contrato.solicitudId ?? 0,
                propertyName: contrato.inmueble!.nombre,
                status: 'contrato_rechazado',
                clientId: contrato.cliente!.id,
                propietarioId: contrato.inmueble!.userId,
              );

              // Show local notification
              _notificationService.showNotification(
                id: id,
                title: 'Contrato Rechazado',
                body: 'El contrato para la propiedad ${contrato.inmueble!.nombre} ha sido rechazado',
                payload: 'contract_rejected_$id',
              );

              print('Contract rejection notification sent');
            } catch (notificationError) {
              print('Error sending contract rejection notification: $notificationError');
            }
          }
        }
        // Refresh the list
        await loadContratosByClienteId();
        isLoading = false;
        return true;
      } else {
        message = response.messageError ?? 'Error al actualizar la aprobación del contrato';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al actualizar la aprobación del contrato: $e';
      isLoading = false;
      return false;
    }
  }

  Future<bool> registrarPagoContrato(int id, DateTime fechaPago, {BuildContext? context}) async {
    try {
      // Initialize services if context is provided and not already initialized
      if (context != null && !_isServicesInitialized()) {
        initializeServices(context);
      }

      isLoading = true;
      // Get the contract to get the amount
      ContratoModel? contrato;
      for (var c in contratos) {
        if (c.id == id) {
          contrato = c;
          break;
        }
      }
      if (contrato == null) {
        message = 'No se encontró el contrato';
        isLoading = false;
        return false;
      }
      ResponseModel response = await _contratoNegocio.updateContratoFechaPago(id, fechaPago);
      if (response.isSuccess) {
        message = 'Pago registrado exitosamente';
        // Update the contract status to active
        await _contratoNegocio.updateContratoEstado(id, 'activo');
        // Check if blockchain is initialized, if not, initialize it
        if (!_blockchainProvider.isInitialized) {
          print('Blockchain not initialized, initializing before making payment...');
          bool initSuccess = await _blockchainProvider.ensureInitialized();
          if (!initSuccess) {
            print('Failed to initialize blockchain service');
            message = '$message (No se pudo inicializar el servicio blockchain)';
            // Continue with payment registration even if blockchain initialization fails
          } else {
            print('Blockchain service initialized successfully');
          }
        }

        // Make payment on blockchain
        try {
          final blockchainSuccess = await _blockchainProvider.makePayment(id, contrato.monto);
          if (blockchainSuccess != null) {
            message = '$message y procesado en blockchain';
            // Update blockchain address if payment was successful
            final blockchainDetails = await _blockchainProvider.getContractDetails(id);
            if (blockchainDetails != null && blockchainDetails.containsKey('landlord')) {
              final blockchainAddress = blockchainDetails['landlord'];
              await updateContratoBlockchain(id, blockchainAddress);
            }
          }
        } catch (blockchainError) {
          // Don't fail the entire operation if blockchain fails
          print('Error making payment on blockchain: $blockchainError');
        }

        // Send notification via WebSocket if services are initialized
        if (_isServicesInitialized() && contrato.cliente != null && contrato.inmueble != null) {
          try {
            // Send WebSocket notification
            _socketService.emitPaymentReceived(
              contratoId: id,
              propertyName: contrato.inmueble!.nombre,
              amount: contrato.monto,
              clientId: contrato.cliente!.id,
              propietarioId: contrato.inmueble!.userId,
            );

            // Show local notification
            _notificationService.showPaymentReceivedNotification(
              contratoId: id,
              propertyName: contrato.inmueble!.nombre,
              amount: contrato.monto,
            );

            print('Payment notification sent');
          } catch (notificationError) {
            print('Error sending payment notification: $notificationError');
          }
        }

        // Refresh the list
        await loadContratosByClienteId();
        isLoading = false;
        return true;
      } else {
        message = response.messageError ?? 'Error al registrar el pago';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al registrar el pago: $e';
      isLoading = false;
      return false;
    }
  }

  Future<bool> updateContratoBlockchain(int id, String blockchainAddress) async {
    try {
      isLoading = true;
      ResponseModel response = await _contratoNegocio.updateContratoBlockchain(id, blockchainAddress);
      if (response.isSuccess) {
        message = 'Dirección blockchain actualizada exitosamente';
        // Refresh the list based on user type
        if (currentUser?.tipoUsuario == 'propietario') {
          await loadContratosByPropietarioId();
        } else {
          await loadContratosByClienteId();
        }
        isLoading = false;
        return true;
      } else {
        message = response.messageError ?? 'Error al actualizar la dirección blockchain';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al actualizar la dirección blockchain: $e';
      isLoading = false;
      return false;
    }
  }

  void selectContrato(ContratoModel contrato) {
    _selectedContrato = contrato;
    notifyListeners();
  }

  String? get message => _message;

  set message(String? value) {
    _message = value;
    notifyListeners();
  }

  bool get isLoading => _isLoading;

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  List<ContratoModel> get contratos => _contratos;

  set contratos(List<ContratoModel> value) {
    _contratos = value;
    notifyListeners();
  }

  ContratoModel? get selectedContrato => _selectedContrato;

  set selectedContrato(ContratoModel? value) {
    _selectedContrato = value;
    notifyListeners();
  }

  UserModel? get currentUser => _currentUser;

  set currentUser(UserModel? value) {
    _currentUser = value;
    notifyListeners();
  }

  MessageType get messageType => _messageType;
  set messageType(MessageType value) {
    _messageType = value;
    notifyListeners();
  }
  List<CondicionalModel> get condicionales => _condicionales;
  set condicionales(List<CondicionalModel> value) {
    _condicionales = value;
    notifyListeners();
  }
}
