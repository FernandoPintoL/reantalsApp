import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../models/solicitud_alquiler_model.dart';
import '../models/response_model.dart';
import '../models/user_model.dart';
import '../negocio/SolicitudAlquilerNegocio.dart';
import '../negocio/SessionNegocio.dart';
import '../negocio/UserNegocio.dart';

class SolicitudAlquilerProvider extends ChangeNotifier {
  final SolicitudAlquilerNegocio _solicitudNegocio = SolicitudAlquilerNegocio();
  final SessionNegocio _sessionNegocio = SessionNegocio();
  final UserNegocio _userNegocio = UserNegocio();
  SessionModelo? _sessionModel;
  
  List<SolicitudAlquilerModel> _solicitudes = [];
  SolicitudAlquilerModel? _selectedSolicitud;
  bool _isLoading = false;
  String? _message;
  UserModel? _currentUser;

  SolicitudAlquilerProvider() {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      _sessionModel = await _sessionNegocio.getSession();
      // cargar al usuario actual
      if (_sessionModel != null && _sessionModel!.userId != null) {
        _currentUser = await _userNegocio.getUser(_sessionModel!.userId!);
      } else {
        _currentUser = null;
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<bool> createSolicitudAlquiler(SolicitudAlquilerModel solicitud) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      if (_currentUser == null) {
        await _loadCurrentUser();
        if (_currentUser == null) {
          message = 'No se pudo cargar el usuario actual';
          isLoading = false;
          return false;
        }
      }

      // Ensure the solicitud is assigned to the current user
      SolicitudAlquilerModel solicitudWithUserId = SolicitudAlquilerModel(
        id: solicitud.id,
        inmuebleId: solicitud.inmuebleId,
        userId: _currentUser!.id,
        estado: solicitud.estado,
        serviciosBasicos: solicitud.serviciosBasicos,
        mensaje: solicitud.mensaje,
        inmueble: solicitud.inmueble,
        cliente: _currentUser,
      );

      ResponseModel response = await _solicitudNegocio.createSolicitudAlquiler(solicitudWithUserId);
      
      if (response.isSuccess && response.data != null) {
        _selectedSolicitud = SolicitudAlquilerModel.fromMap(response.data);
        message = 'Solicitud de alquiler enviada exitosamente';
        await loadSolicitudesByUserId(); // Refresh the list
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

  Future<void> loadSolicitudesByUserId() async {
    if (_currentUser == null) {
      await _loadCurrentUser();
      if (_currentUser == null) {
        message = 'No se pudo cargar el usuario actual';
        return;
      }
    }

    _isLoading = true;
    notifyListeners();
    
    try {
      ResponseModel response = await _solicitudNegocio.getSolicitudesByUserId(_currentUser!.id);
      
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
    if (_currentUser == null) {
      await _loadCurrentUser();
      if (_currentUser == null) {
        message = 'No se pudo cargar el usuario actual';
        return;
      }
    }

    _isLoading = true;
    notifyListeners();
    
    try {
      ResponseModel response = await _solicitudNegocio.getSolicitudesByPropietarioId(_currentUser!.id);
      
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
        if (_currentUser?.tipoUsuario == 'propietario') {
          await loadSolicitudesByPropietarioId();
        } else {
          await loadSolicitudesByUserId();
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
}