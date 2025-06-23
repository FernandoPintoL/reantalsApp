import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../models/solicitud_alquiler_model.dart';
import '../models/response_model.dart';
import '../models/user_model.dart';
import '../negocio/AuthenticatedNegocio.dart';
import '../negocio/SolicitudAlquilerNegocio.dart';
import '../negocio/SessionNegocio.dart';
import '../negocio/UserNegocio.dart';
import '../vista/components/message_widget.dart';

class SolicitudAlquilerProvider extends ChangeNotifier {
  final SolicitudAlquilerNegocio _solicitudNegocio = SolicitudAlquilerNegocio();
  final AuthenticatedNegocio _authenticatedNegocio = AuthenticatedNegocio();

  late ResponseModel _responseModel;
  
  List<SolicitudAlquilerModel> _solicitudes = [];
  SolicitudAlquilerModel? _selectedSolicitud;
  bool _isLoading = false;
  String? _message;
  UserModel? _currentUser;
  MessageType _messageType = MessageType.info;

  SolicitudAlquilerProvider() {
    _loadCurrentUser();
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
  Future<bool> createSolicitudAlquiler(SolicitudAlquilerModel solicitud) async {

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
        serviciosBasicos: solicitud.serviciosBasicos,
        mensaje: solicitud.mensaje,
        inmueble: solicitud.inmueble,
        cliente: currentUser,
      );

      ResponseModel response = await _solicitudNegocio.createSolicitudAlquiler(solicitudWithUserId);
      
      if (response.isSuccess && response.data != null) {
        _selectedSolicitud = SolicitudAlquilerModel.fromMap(response.data);
        message = 'Solicitud de alquiler enviada exitosamente';
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

    _isLoading = true;
    notifyListeners();
    
    try {
      ResponseModel response = await _solicitudNegocio.getSolicitudesByClienteId(currentUser!.id);
      
      if (response.isSuccess && response.data != null) {
        solicitudes = SolicitudAlquilerModel.fromJsonList(response.data);
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

  Future<bool> updateSolicitudEstado(int id, String estado) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      ResponseModel response = await _solicitudNegocio.updateSolicitudEstado(id, estado);
      
      if (response.isSuccess) {
        message = 'Estado de la solicitud actualizado exitosamente';
        
        // Refresh the list based on user type
        if (currentUser?.tipoUsuario == 'propietario') {
          await loadSolicitudesByPropietarioId();
        } else {
          await loadSolicitudesByClienteId();
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

}