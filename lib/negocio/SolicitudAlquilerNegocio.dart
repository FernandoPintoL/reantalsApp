import '../services/ApiService.dart';
import '../models/solicitud_alquiler_model.dart';
import '../models/response_model.dart';

class SolicitudAlquilerNegocio {
  final ApiService apiService;

  SolicitudAlquilerNegocio({ApiService? apiService}) : this.apiService = apiService ?? ApiService.getInstance();

  Future<ResponseModel> createSolicitudAlquiler(SolicitudAlquilerModel solicitud) async {
    try {
      ResponseModel response = await apiService.post('solicitudes-alquiler', solicitud.toMap());
      print('Response from createSolicitudAlquiler: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error creating solicitud alquiler: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error creating solicitud alquiler: $e',
        statusCode: 500,
        data: null,
        message: 'Error creating solicitud alquiler: $e',
      );
    }
  }

  Future<ResponseModel> getSolicitudesByClienteId(int userId) async {
    try {
      ResponseModel response = await apiService.get('solicitudes-alquiler/cliente/$userId');
      print('Response from getSolicitudesByUserId: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error fetching solicitudes by user id: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error fetching solicitudes by user id: $e',
        statusCode: 500,
        data: null,
        message: 'Error fetching solicitudes by user id: $e',
      );
    }
  }

  Future<ResponseModel> getSolicitudesByPropietarioId(int propietarioId) async {
    try {
      ResponseModel response = await apiService.get('solicitudes-alquiler/propietario/$propietarioId');
      print('Response from getSolicitudesByPropietarioId: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error fetching solicitudes by propietario id: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error fetching solicitudes by propietario id: $e',
        statusCode: 500,
        data: null,
        message: 'Error fetching solicitudes by propietario id: $e',
      );
    }
  }

  Future<ResponseModel> getSolicitudById(int id) async {
    try {
      ResponseModel response = await apiService.get('solicitudes-alquiler/$id');
      print('Response from getSolicitudById: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error fetching solicitud by id: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error fetching solicitud by id: $e',
        statusCode: 500,
        data: null,
        message: 'Error fetching solicitud by id: $e',
      );
    }
  }

  Future<ResponseModel> updateSolicitudEstado(int id, String estado) async {
    try {
      ResponseModel response = await apiService.put('solicitudes-alquiler/$id/estado', {'estado': estado});
      print('Response from updateSolicitudEstado: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error updating solicitud estado: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error updating solicitud estado: $e',
        statusCode: 500,
        data: null,
        message: 'Error updating solicitud estado: $e',
      );
    }
  }
}