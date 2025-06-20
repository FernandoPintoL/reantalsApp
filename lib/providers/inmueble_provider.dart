import 'package:flutter/material.dart';
import '../../models/inmueble_model.dart';
import '../../models/response_model.dart';
import '../../models/galeria_inmueble_model.dart';
import '../../models/user_model.dart';
import '../../negocio/InmuebleNegocio.dart';
import '../../negocio/SessionNegocio.dart';
import '../models/session_model.dart';
import '../negocio/UserNegocio.dart';

class InmuebleProvider extends ChangeNotifier {
  final InmuebleNegocio _inmuebleNegocio = InmuebleNegocio();
  final SessionNegocio _sessionNegocio = SessionNegocio();
  final UserNegocio _userNegocio = UserNegocio();
  late ResponseModel _responseModel;
  List<InmuebleModel> _inmuebles = [];
  List<GaleriaInmuebleModel> _galeriaInmueble = [];
  InmuebleModel? _selectedInmueble;
  bool _isLoading = false;
  String? _message;
  UserModel? _currentUser;
  SessionModelo? _sessionModel;

  InmuebleProvider() {
    loadInmuebles();
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

  Future<void> loadInmuebles() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Simula una llamada a la base de datos para obtener inmuebles
      _responseModel = await _inmuebleNegocio.getInmuebles("");
      if (_responseModel.isSuccess && _responseModel.data != null) {
        inmuebles = InmuebleModel.fromList(_responseModel.data);
        message = null; // Reset message on successful load
      } else {
        message = _responseModel.messageError ?? 'No se encontraron inmuebles';
      }
    } catch (e) {
      message = 'Error al cargar los inmuebles: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadInmueblesByPropietarioId() async {
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
      _responseModel = await _inmuebleNegocio.getInmueblesByPropietarioId(_currentUser!.id);
      if (_responseModel.isSuccess && _responseModel.data != null) {
        inmuebles = InmuebleModel.fromList(_responseModel.data);
        message = null; // Reset message on successful load
      } else {
        message = _responseModel.messageError ?? 'No se encontraron inmuebles para este propietario';
      }
    } catch (e) {
      message = 'Error al cargar los inmuebles del propietario: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadInmuebleGaleria(int inmuebleId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _responseModel = await _inmuebleNegocio.getInmuebleGaleria(inmuebleId);
      if (_responseModel.isSuccess && _responseModel.data != null) {
        _galeriaInmueble = GaleriaInmuebleModel.fromJsonList(_responseModel.data);
        message = null; // Reset message on successful load
      } else {
        message = _responseModel.messageError ?? 'No se encontraron imágenes para este inmueble';
      }
    } catch (e) {
      message = 'Error al cargar las imágenes del inmueble: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<bool> createInmueble(InmuebleModel inmueble) async {
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

      // Ensure the property is assigned to the current user
      InmuebleModel inmuebleWithUserId = InmuebleModel(
        id: inmueble.id,
        userId: _currentUser!.id,
        nombre: inmueble.nombre,
        detalle: inmueble.detalle,
        numHabitacion: inmueble.numHabitacion,
        numPiso: inmueble.numPiso,
        precio: inmueble.precio,
        isOcupado: inmueble.isOcupado,
        accesorios: inmueble.accesorios,
        servicios_basicos: inmueble.servicios_basicos,
        tipoInmuebleId: inmueble.tipoInmuebleId,
      );

      _responseModel = await _inmuebleNegocio.createInmueble(inmuebleWithUserId);
      if (_responseModel.isSuccess && _responseModel.data != null) {
        _selectedInmueble = InmuebleModel.fromList(_responseModel.data).first;
        message = 'Inmueble creado exitosamente';
        await loadInmueblesByPropietarioId(); // Refresh the list
        isLoading = false;
        return true;
      } else {
        message = _responseModel.messageError ?? 'Error al crear el inmueble';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al crear el inmueble: $e';
      isLoading = false;
      return false;
    }
  }

  Future<bool> updateInmueble(InmuebleModel inmueble) async {
    _isLoading = true;
    notifyListeners();
    try {
      _responseModel = await _inmuebleNegocio.updateInmueble(inmueble);
      if (_responseModel.isSuccess && _responseModel.data != null) {
        _selectedInmueble = InmuebleModel.fromList(_responseModel.data).first;
        message = 'Inmueble actualizado exitosamente';
        await loadInmueblesByPropietarioId(); // Refresh the list
        isLoading = false;
        return true;
      } else {
        message = _responseModel.messageError ?? 'Error al actualizar el inmueble';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al actualizar el inmueble: $e';
      isLoading = false;
      return false;
    }
  }

  Future<bool> deleteInmueble(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _responseModel = await _inmuebleNegocio.deleteInmueble(id);
      if (_responseModel.isSuccess) {
        message = 'Inmueble eliminado exitosamente';
        await loadInmueblesByPropietarioId(); // Refresh the list
        isLoading = false;
        return true;
      } else {
        message = _responseModel.messageError ?? 'Error al eliminar el inmueble';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al eliminar el inmueble: $e';
      isLoading = false;
      return false;
    }
  }

  Future<bool> uploadInmuebleImage(int inmuebleId, String filePath) async {
    _isLoading = true;
    notifyListeners();
    try {
      _responseModel = await _inmuebleNegocio.uploadInmuebleImage(inmuebleId, filePath);
      if (_responseModel.isSuccess && _responseModel.data != null) {
        message = 'Imagen subida exitosamente';
        await loadInmuebleGaleria(inmuebleId); // Refresh the gallery
        isLoading = false;
        return true;
      } else {
        message = _responseModel.messageError ?? 'Error al subir la imagen';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al subir la imagen: $e';
      isLoading = false;
      return false;
    }
  }

  Future<bool> deleteInmuebleImage(int galeriaId, int inmuebleId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _responseModel = await _inmuebleNegocio.deleteInmuebleImage(galeriaId);
      if (_responseModel.isSuccess) {
        message = 'Imagen eliminada exitosamente';
        await loadInmuebleGaleria(inmuebleId); // Refresh the gallery
        isLoading = false;
        return true;
      } else {
        message = _responseModel.messageError ?? 'Error al eliminar la imagen';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al eliminar la imagen: $e';
      isLoading = false;
      return false;
    }
  }

  void selectInmueble(InmuebleModel inmueble) {
    _selectedInmueble = inmueble;
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

  List<InmuebleModel> get inmuebles => _inmuebles;

  set inmuebles(List<InmuebleModel> value) {
    _inmuebles = value;
    notifyListeners();
  }

  List<GaleriaInmuebleModel> get galeriaInmueble => _galeriaInmueble;

  InmuebleModel? get selectedInmueble => _selectedInmueble;

  UserModel? get currentUser => _currentUser;
}
