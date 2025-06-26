import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/solicitud_alquiler_model.dart';
import '../models/response_model.dart';
import '../models/user_model.dart';
import '../negocio/AuthenticatedNegocio.dart';
import '../negocio/SolicitudAlquilerNegocio.dart';
import '../negocio/InmuebleNegocio.dart';
import '../services/notification_service.dart';
import '../services/socket_service.dart';
import '../services/ApiService.dart';
import '../vista/components/message_widget.dart';

class SolicitudAlquilerProvider extends ChangeNotifier {
  final SolicitudAlquilerNegocio _solicitudNegocio = SolicitudAlquilerNegocio();
  final AuthenticatedNegocio _authenticatedNegocio = AuthenticatedNegocio();
  final InmuebleNegocio _inmuebleNegocio = InmuebleNegocio();
  final ApiService _apiService = ApiService.getInstance();

  // Services for notifications
  late SocketService _socketService;
  late NotificationService _notificationService;
  final BuildContext? _context;

  List<SolicitudAlquilerModel> _solicitudes = [];
  SolicitudAlquilerModel? _selectedSolicitud;
  bool _isLoading = false;
  String? _message;
  UserModel? _currentUser;
  MessageType _messageType = MessageType.info;

  SolicitudAlquilerProvider({BuildContext? context}) : _context = context {
    _loadCurrentUser();

    // Initialize services if context is provided
    if (_context != null) {
      _socketService = Provider.of<SocketService>(_context!, listen: false);
      _notificationService = Provider.of<NotificationService>(_context!, listen: false);
    }
  }

  // Method to initialize services if not done in constructor
  void initializeServices(BuildContext context) {
    _socketService = Provider.of<SocketService>(context, listen: false);
    _notificationService = Provider.of<NotificationService>(context, listen: false);
  }

  // Helper method to check if services are initialized
  bool _isServicesInitialized() {
    try {
      return true; // Services are initialized with 'late' keyword
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      print('Cargando usuario actual solicitud de alquiler...');
      currentUser = await _authenticatedNegocio.getUserSession();
      if (_currentUser == null) {
        messageType = MessageType.info;
        message = 'No se pudo cargar el usuario actual';
      }
    } catch (e) {
      messageType = MessageType.error;
      print('Error loading current user: $e');
    }
  }
  // el que realiza la solicitud de alquiler es el cliente, por lo que se asigna el userId del cliente a la solicitud
  Future<bool> createSolicitudAlquiler(SolicitudAlquilerModel solicitud, {BuildContext? context}) async {
    // Initialize services if context is provided and not already initialized
    if (context != null && !_isServicesInitialized()) {
      initializeServices(context);
    }

    try {
      isLoading = true;
      if (solicitud.userId == null || solicitud.userId == 0) {
        await _loadCurrentUser();
        if (currentUser == null) {
          message = 'No se pudo cargar el usuario actual';
          isLoading = false;
          return false;
        }
      }

      // Ensure the solicitud is assigned to the current user
      SolicitudAlquilerModel solicitudWithUserId = SolicitudAlquilerModel(
        id: solicitud.id,
        inmuebleId: solicitud.inmuebleId,
        userId: currentUser!.id,
        estado: solicitud.estado,
        servicios_basicos: solicitud.servicios_basicos,
        mensaje: solicitud.mensaje,
        inmueble: solicitud.inmueble,
        cliente: currentUser,
      );

      ResponseModel response = await _solicitudNegocio.createSolicitudAlquiler(solicitudWithUserId);
      print('Response from createSolicitudAlquiler: ${response.toJson()}');
      if (response.isSuccess && response.data != null) {
        _selectedSolicitud = SolicitudAlquilerModel.fromMap(response.data);
        message = 'Solicitud de alquiler enviada exitosamente';

        // Send notification via WebSocket if services are initialized
        if (_isServicesInitialized() && solicitud.inmueble != null) {
          try {
            // Get the property owner ID
            int propietarioId = solicitud.inmueble!.userId;

            // Send WebSocket notification
            _socketService.emitRequestStatusChanged(
              solicitudId: _selectedSolicitud!.id,
              propertyName: solicitud.inmueble!.nombre,
              status: 'pendiente', // New request is always pending
              clientId: currentUser!.id,
              propietarioId: propietarioId,
            );

            // Show local notification to the property owner
            _notificationService.showNotification(
              id: _selectedSolicitud!.id,
              title: 'Nueva Solicitud de Alquiler',
              body: 'Has recibido una nueva solicitud para la propiedad: ${solicitud.inmueble!.nombre}',
              payload: 'new_request_${_selectedSolicitud!.id}',
            );

            print('New rental request notification sent');
          } catch (notificationError) {
            print('Error sending new rental request notification: $notificationError');
          }
        }

        await loadSolicitudesByClienteId(); // Refresh the list
        isLoading = false;
        return true;
      } else {
        message = response.messageError ?? 'Error al crear la solicitud de alquiler';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al crear la solicitud de alquiler: $e';
      isLoading = false;
      return false;
    }
  }

  Future<void> loadSolicitudesByClienteId() async {
    if (currentUser == null) {
      await _loadCurrentUser();
      if (currentUser == null) {
        message = 'No se pudo cargar el usuario actual';
        return;
      }
    }

    try {
      isLoading = true;
      ResponseModel response = await _solicitudNegocio.getSolicitudesByClienteId(currentUser!.id);
      print('Response from getSolicitudesByClienteId: ${response.toJson()}');
      if (response.isSuccess && response.data != null) {
        solicitudes = SolicitudAlquilerModel.fromJsonList(response.data);

        // Ensure complete data for each solicitud
        for (var solicitud in _solicitudes) {
          await _ensurePropertyDataComplete(solicitud);
          await _ensureUserDataComplete(solicitud);
        }

        print('Solicitudes loaded: ${solicitudes.length}');
        message = null; // Reset message on successful load
      } else {
        message = response.messageError ?? 'No se encontraron solicitudes para este usuario';
      }
    } catch (e) {
      message = 'Error al cargar las solicitudes del usuario: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadSolicitudesByPropietarioId() async {
    if (currentUser == null) {
      await _loadCurrentUser();
      if (currentUser == null) {
        message = 'No se pudo cargar el usuario actual';
        return;
      }
    }

    _isLoading = true;
    notifyListeners();

    try {
      ResponseModel response = await _solicitudNegocio.getSolicitudesByPropietarioId(currentUser!.id);

      if (response.isSuccess && response.data != null) {
        solicitudes = SolicitudAlquilerModel.fromJsonList(response.data);

        // Ensure complete data for each solicitud
        for (var solicitud in _solicitudes) {
          await _ensurePropertyDataComplete(solicitud);
          await _ensureUserDataComplete(solicitud);
        }

        message = null; // Reset message on successful load
      } else {
        message = response.messageError ?? 'No se encontraron solicitudes para este propietario';
      }
    } catch (e) {
      message = 'Error al cargar las solicitudes del propietario: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<bool> updateSolicitudEstado(int id, String estado, {BuildContext? context}) async {
    // Initialize services if context is provided and not already initialized
    if (context != null && !_isServicesInitialized()) {
      initializeServices(context);
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Get the solicitud before updating to have access to its data
      SolicitudAlquilerModel? solicitud;
      for (var s in _solicitudes) {
        if (s.id == id) {
          solicitud = s;
          break;
        }
      }

      ResponseModel response = await _solicitudNegocio.updateSolicitudEstado(id, estado);

      if (response.isSuccess) {
        message = 'Estado de la solicitud actualizado exitosamente';

        // Refresh the list based on user type
        if (currentUser?.tipoUsuario == 'propietario') {
          await loadSolicitudesByPropietarioId();
        } else {
          await loadSolicitudesByClienteId();
        }

        // Send notification via WebSocket if services are initialized and we have the solicitud data
        if (_isServicesInitialized() && solicitud != null && solicitud.inmueble != null && solicitud.cliente != null) {
          try {
            // Send WebSocket notification
            _socketService.emitRequestStatusChanged(
              solicitudId: id,
              propertyName: solicitud.inmueble!.nombre,
              status: estado,
              clientId: solicitud.cliente!.id,
              propietarioId: solicitud.inmueble!.userId,
            );

            // Show local notification
            _notificationService.showRequestStatusChangedNotification(
              solicitudId: id,
              propertyName: solicitud.inmueble!.nombre,
              status: estado,
            );

            print('Request status change notification sent');
          } catch (notificationError) {
            print('Error sending request status change notification: $notificationError');
          }
        } else if (_isServicesInitialized()) {
          // If we don't have the solicitud data, try to get it from the response
          try {
            // Try to get the updated solicitud from the response
            if (response.data != null) {
              SolicitudAlquilerModel updatedSolicitud = SolicitudAlquilerModel.fromMap(response.data);
              if (updatedSolicitud.inmueble != null && updatedSolicitud.cliente != null) {
                // Send WebSocket notification
                _socketService.emitRequestStatusChanged(
                  solicitudId: id,
                  propertyName: updatedSolicitud.inmueble!.nombre,
                  status: estado,
                  clientId: updatedSolicitud.cliente!.id,
                  propietarioId: updatedSolicitud.inmueble!.userId,
                );

                // Show local notification
                _notificationService.showRequestStatusChangedNotification(
                  solicitudId: id,
                  propertyName: updatedSolicitud.inmueble!.nombre,
                  status: estado,
                );

                print('Request status change notification sent (from response data)');
              }
            }
          } catch (notificationError) {
            print('Error sending request status change notification from response data: $notificationError');
          }
        }

        isLoading = false;
        return true;
      } else {
        message = response.messageError ?? 'Error al actualizar el estado de la solicitud';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al actualizar el estado de la solicitud: $e';
      isLoading = false;
      return false;
    }
  }

  void selectSolicitud(SolicitudAlquilerModel solicitud) {
    _selectedSolicitud = solicitud;
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

  List<SolicitudAlquilerModel> get solicitudes => _solicitudes;

  set solicitudes(List<SolicitudAlquilerModel> value) {
    _solicitudes = value;
    notifyListeners();
  }

  SolicitudAlquilerModel? get selectedSolicitud => _selectedSolicitud;

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

  // Fetch user data from API
  Future<UserModel?> _fetchUserFromApi(int userId) async {
    try {
      ResponseModel response = await _apiService.get('users/$userId');
      if (response.isSuccess && response.data != null) {
        return UserModel.mapToModel(response.data);
      }
      return null;
    } catch (e) {
      print('Error fetching user from API: $e');
      return null;
    }
  }

  // Ensure property data is complete
  Future<void> _ensurePropertyDataComplete(SolicitudAlquilerModel solicitud) async {
    if (solicitud.inmueble == null || solicitud.inmueble!.nombre.isEmpty) {
      try {
        final inmueble = await _inmuebleNegocio.getInmuebleById(solicitud.inmuebleId);
        if (inmueble != null) {
          solicitud.inmueble = inmueble;
        }
      } catch (e) {
        print('Error fetching property data: $e');
      }
    }
  }

  // Ensure user data is complete
  Future<void> _ensureUserDataComplete(SolicitudAlquilerModel solicitud) async {
    if (solicitud.cliente == null || solicitud.cliente!.name.isEmpty) {
      try {
        final user = await _fetchUserFromApi(solicitud.userId);
        if (user != null) {
          solicitud.cliente = user;
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

}
