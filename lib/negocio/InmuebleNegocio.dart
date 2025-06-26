import '../services/ApiService.dart';
import '../models/inmueble_model.dart';
import '../models/response_model.dart';

class InmuebleNegocio {
  final ApiService apiService;

  InmuebleNegocio({ApiService? apiService}) : this.apiService = apiService ?? ApiService.getInstance();

  Future<ResponseModel> getInmuebles(String query) async {
    try {
      ResponseModel response = await apiService.post('inmuebles/query',{'query': query});
      print('Response from getAllInmuebles: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error fetching inmuebles: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error fetching inmuebles: $e',
        statusCode: 500,
        data: null,
        message: 'Error fetching inmuebles: $e',
      );
    }
  }

  Future<ResponseModel> getTipoInmueble() async {
    try {
      ResponseModel response = await apiService.post('tipoinmueble/query', {'query': ''});
      print('Response from getTipoInmueble: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error fetching tipo inmueble: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error fetching tipo inmueble: $e',
        statusCode: 500,
        data: null,
        message: 'Error fetching tipo inmueble: $e',
      );
    }
  }

  Future<ResponseModel> getInmueblesByPropietarioId(int propietarioId) async {
    try {
      ResponseModel response = await apiService.get('inmuebles/propietario/$propietarioId');
      print('Response from getInmueblesByPropietarioId: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error fetching inmuebles by propietario id: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error fetching inmuebles by propietario id: $e',
        statusCode: 500,
        data: null,
        message: 'Error fetching inmuebles by propietario id: $e',
      );
    }
  }

  Future<InmuebleModel?> getInmuebleById(int id) async {
    try {
      InmuebleModel? i;
      ResponseModel response = await apiService.get('inmuebles/$id');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        i = InmuebleModel.mapToModel(response.data);
      }
      return i;
    } catch (e) {
      print('Error fetching inmueble by id: $e');
      return null;
    }
  }

  Future<ResponseModel> createInmueble(InmuebleModel inmueble) async {
    try {
      ResponseModel response = await apiService.post('inmuebles/store', inmueble.toMap());
      print('Response from createInmueble: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error creating inmueble: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error creating inmueble: $e',
        statusCode: 500,
        data: null,
        message: 'Error creating inmueble: $e',
      );
    }
  }

  Future<ResponseModel> updateInmueble(InmuebleModel inmueble) async {
    try {
      ResponseModel response = await apiService.put('inmuebles/${inmueble.id}', inmueble.toMap());
      return response;
    } catch (e) {
      print('Error updating inmueble: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error updating inmueble: $e',
        statusCode: 500,
        data: null,
        message: 'Error updating inmueble: $e',
      );
    }
  }

  Future<ResponseModel> deleteInmueble(int id) async {
    try {
      ResponseModel response = await apiService.delete('inmuebles/$id');
      print('Response from deleteInmueble: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error deleting inmueble: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error deleting inmueble: $e',
        statusCode: 500,
        data: null,
        message: 'Error deleting inmueble: $e',
      );
    }
  }

  Future<ResponseModel> uploadInmuebleImage(int inmuebleId, String filePath) async {
    try {
      ResponseModel response = await apiService.uploadFile('inmuebles/subir-imagen', filePath, inmuebleId);
      return response;
    } catch (e) {
      print('Error uploading inmueble image: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error uploading inmueble image: $e',
        statusCode: 500,
        data: null,
        message: 'Error uploading inmueble image: $e',
      );
    }
  }

  Future<ResponseModel> getInmuebleGaleria(int inmuebleId) async {
    try {
      ResponseModel response = await apiService.get('inmuebles/$inmuebleId/galeria');
      return response;
    } catch (e) {
      print('Error fetching inmueble galeria: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error fetching inmueble galeria: $e',
        statusCode: 500,
        data: null,
        message: 'Error fetching inmueble galeria: $e',
      );
    }
  }

  Future<ResponseModel> getFirstImage(int inmuebleId) async {
    try {
      ResponseModel response = await apiService.get('inmuebles/$inmuebleId/galeria/first');
      print('Response from getFirstImage: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error fetching first image: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error fetching first image: $e',
        statusCode: 500,
        data: null,
        message: 'Error fetching first image: $e',
      );
    }
  }

  Future<ResponseModel> deleteInmuebleImage(int galeriaId) async {
    try {
      ResponseModel response = await apiService.delete('inmuebles/galeria/$galeriaId');
      print('Response from deleteInmuebleImage: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error deleting inmueble image: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error deleting inmueble image: $e',
        statusCode: 500,
        data: null,
        message: 'Error deleting inmueble image: $e',
      );
    }
  }
}
