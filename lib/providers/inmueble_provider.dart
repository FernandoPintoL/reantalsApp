import 'package:flutter/material.dart';
import '../../models/inmueble_model.dart';
import '../../models/response_model.dart';
import '../../models/galeria_inmueble_model.dart';
import '../../models/user_model.dart';
import '../../negocio/InmuebleNegocio.dart';
import '../models/tipo_inmueble_model.dart';
import '../models/servicio_basico_model.dart';
import '../negocio/AuthenticatedNegocio.dart';

class InmuebleProvider extends ChangeNotifier {
  final InmuebleNegocio _inmuebleNegocio = InmuebleNegocio();
  final AuthenticatedNegocio _authenticatedNegocio = AuthenticatedNegocio();
  late ResponseModel _responseModel;
  List<InmuebleModel> _inmuebles = [];
  List<InmuebleModel> _myInmuebles = [];
  List<GaleriaInmuebleModel> _galeriaInmueble = [];
  List<TipoInmuebleModel> _tipoInmuebles = [];
  List<ServicioBasicoModel> _serviciosBasicos = [];
  InmuebleModel? _selectedInmueble;
  bool _isLoading = false;
  String? _message;
  UserModel? _currentUser;

  InmuebleProvider() {
    loadInmuebles();
    _loadCurrentUser();
    loadServiciosBasicos();
  }

  Future<void> _loadCurrentUser() async {
    try {
      isLoading = true;
      currentUser = await _authenticatedNegocio.getUserSession();
      if (currentUser == null) {
        message = 'Usuario no encontrado, se ha creado un usuario temporal';
      }
    } catch (e) {
      message = 'Error al cargar el usuario actual: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadInmuebles() async {
    try {
      isLoading = true;
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
    print('Cargando inmuebles por propietario ID');
    if (currentUser == null) {
      await _loadCurrentUser();
      if (currentUser == null) {
        message = 'No se pudo cargar el usuario actual';
        return;
      }
    }

    print('Usuario actual cargado: ${currentUser?.id}');

    try {
      isLoading = true;
      _responseModel = await _inmuebleNegocio.getInmueblesByPropietarioId(currentUser!.id);
      print('Respuesta del negocio: ${_responseModel.isSuccess}, Data: ${_responseModel.data}');
      if (_responseModel.isSuccess && _responseModel.data != null) {
        myInmuebles = InmuebleModel.fromList(_responseModel.data);
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
    try {
      isLoading = true;
      _responseModel = await _inmuebleNegocio.getInmuebleGaleria(inmuebleId);
      if (_responseModel.isSuccess && _responseModel.data != null) {
        galeriaInmueble = GaleriaInmuebleModel.fromJsonList(_responseModel.data);
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

  Future<void> loadTipoInmueble() async {
    try {
      isLoading = true;
      _responseModel = await _inmuebleNegocio.getTipoInmueble();
      if (_responseModel.isSuccess && _responseModel.data != null) {
        tipoInmuebles = TipoInmuebleModel.fromList(_responseModel.data);
        print('Tipos de inmueble cargados: ${tipoInmuebles.length}');
        message = null; // Reset message on successful load
      } else {
        message = _responseModel.messageError ?? 'No se encontraron tipos de inmueble';
      }
    } catch (e) {
      message = 'Error al cargar los tipos de inmueble: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<String> getFirstImageUrl(int inmuebleId) async {
    try {
      _responseModel = await _inmuebleNegocio.getInmuebleGaleria(inmuebleId);
      print('Respuesta del negocio al obtener la galería: ${_responseModel.isSuccess}, Data: ${_responseModel.data}');
      if (_responseModel.isSuccess && _responseModel.data != null) {
        List<GaleriaInmuebleModel> galerias = GaleriaInmuebleModel.fromJsonList(_responseModel.data);
        if (galerias.isNotEmpty) {
          // Return the URL of the first image
          return galerias.first.photoPath ?? '';
        }
      }
      return ''; // Return empty string if no images found
    } catch (e) {
      print('Error al obtener la primera imagen: $e');
      return '';
    } finally {
      isLoading = false;
    }
  }

  Future<bool> createInmueble(InmuebleModel inmueble) async {
    try {
      isLoading = true;
      if (currentUser == null || inmueble.userId == 0) {
        message = 'No se pudo cargar el usuario actual';
        isLoading = false;
        print('Error: No se pudo cargar el usuario actual');
        return false;
      }

      // Ensure the property is assigned to the current user
      /*InmuebleModel inmuebleWithUserId = InmuebleModel(
        id: inmueble.id,
        userId: currentUser!.id,
        nombre: inmueble.nombre,
        detalle: inmueble.detalle,
        numHabitacion: inmueble.numHabitacion,
        numPiso: inmueble.numPiso,
        precio: inmueble.precio,
        isOcupado: inmueble.isOcupado,
        accesorios: inmueble.accesorios,
        servicios_basicos: inmueble.servicios_basicos,
        tipoInmuebleId: inmueble.tipoInmuebleId,
      );*/

      _responseModel = await _inmuebleNegocio.createInmueble(inmueble);
      print('Respuesta del negocio al crear inmueble: ${_responseModel.isSuccess}, Data: ${_responseModel.data}');
      if (_responseModel.isSuccess && _responseModel.data != null) {
        _selectedInmueble = InmuebleModel.mapToModel(_responseModel.data);
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
      print('Error al crear el inmueble: $e');
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<bool> updateInmueble(InmuebleModel inmueble) async {
    try {
      isLoading = true;
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
    } finally {
      isLoading = false;
    }
  }

  Future<bool> deleteInmueble(int id) async {
    try {
      isLoading = true;
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
    try {
      isLoading = true;
      _responseModel = await _inmuebleNegocio.uploadInmuebleImage(inmuebleId, filePath);
      print('Respuesta del negocio al subir imagen: ${_responseModel.isSuccess}, Data: ${_responseModel.data}');
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
    } finally {
      isLoading = false;
    }
  }

  Future<bool> deleteInmuebleImage(int galeriaId, int inmuebleId) async {
    try {
      isLoading = true;
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
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadServiciosBasicos() async {
    try {
      isLoading = true;
      // Load default basic services
      _serviciosBasicos = ServicioBasicoModel.getDefaultServicios();

      // If editing an existing property, mark the services that are already selected
      if (_selectedInmueble != null && _selectedInmueble!.servicios_basicos != null) {
        for (var servicio in _serviciosBasicos) {
          servicio.isSelected = _selectedInmueble!.servicios_basicos!.any(
            (s) => s.id == servicio.id
          );
        }
      }

      message = null; // Reset message on successful load
    } catch (e) {
      message = 'Error al cargar los servicios básicos: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<void> clear() async {
    _inmuebles.clear();
    _myInmuebles.clear();
    _galeriaInmueble.clear();
    _tipoInmuebles.clear();
    _serviciosBasicos.clear();
    _selectedInmueble = null;
    _message = null;
    _isLoading = false;
    notifyListeners();
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

  List<TipoInmuebleModel> get tipoInmuebles => _tipoInmuebles;

  InmuebleModel? get selectedInmueble => _selectedInmueble;

  UserModel? get currentUser => _currentUser;
  set currentUser(UserModel? value) {
    _currentUser = value;
    notifyListeners();
  }
  set galeriaInmueble(List<GaleriaInmuebleModel> value) {
    _galeriaInmueble = value;
    notifyListeners();
  }

  set tipoInmuebles(List<TipoInmuebleModel> value) {
    _tipoInmuebles = value;
    notifyListeners();
  }

  List<ServicioBasicoModel> get serviciosBasicos => _serviciosBasicos;

  set serviciosBasicos(List<ServicioBasicoModel> value) {
    _serviciosBasicos = value;
    notifyListeners();
  }
  set selectedInmueble(InmuebleModel? value) {
    _selectedInmueble = value;
    notifyListeners();
  }

  List<InmuebleModel> get myInmuebles => _myInmuebles;

  set myInmuebles(List<InmuebleModel> value) {
    _myInmuebles = value;
    notifyListeners();
  }


}
