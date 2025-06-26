import '../services/ApiService.dart';
import '../models/pago_model.dart';
import '../models/response_model.dart';

class PagoNegocio {
  final ApiService apiService;

  PagoNegocio({ApiService? apiService}) : this.apiService = apiService ?? ApiService.getInstance();

  Future<ResponseModel> createPago(PagoModel pago) async {
    try {
      ResponseModel response = await apiService.post('pagos/store', pago.toJson());
      print('Response from createPago: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error creating pago: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error creating pago: $e',
        statusCode: 500,
        data: null,
        message: 'Error creating pago: $e',
      );
    }
  }

  Future<ResponseModel> getPagosContratoId(int contratoId) async {
    try {
      ResponseModel response = await apiService.get('pagos/contrato/$contratoId');
      print('Response from getPagosByContratoId: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error fetching pagos by contrato id: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error fetching pagos by contrato id: $e',
        statusCode: 500,
        data: null,
        message: 'Error fetching pagos by contrato id: $e',
      );
    }
  }

  Future<ResponseModel> getPagosByClienteId(int userId) async {
    try {
      ResponseModel response = await apiService.get('pagos/cliente/$userId');
      print('Response from getPagosByUserId: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error fetching pagos by user id: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error fetching pagos by user id: $e',
        statusCode: 500,
        data: null,
        message: 'Error fetching pagos by user id: $e',
      );
    }
  }

  Future<ResponseModel> getPagosPendientesByClienteId(int userId) async {
    try {
      ResponseModel response = await apiService.get('pagos/pendientes/cliente/$userId');
      print('Response from getPagosPendientesByClienteId: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error fetching pagos pendientes by user id: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error fetching pagos pendientes by user id: $e',
        statusCode: 500,
        data: null,
        message: 'Error fetching pagos pendientes by user id: $e',
      );
    }
  }

  Future<ResponseModel> getPagosCompletadosByClienteId(int userId) async {
    try {
      ResponseModel response = await apiService.get('pagos/completados/cliente/$userId');
      print('Response from getPagosCompletadosByClienteId: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error fetching pagos completados by user id: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error fetching pagos completados by user id: $e',
        statusCode: 500,
        data: null,
        message: 'Error fetching pagos completados by user id: $e',
      );
    }
  }

  Future<ResponseModel> updatePagoEstado(int id, String estado) async {
    try {
      ResponseModel response = await apiService.put('pagos/$id/estado', {'estado': estado});
      print('Response from updatePagoEstado: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error updating pago estado: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error updating pago estado: $e',
        statusCode: 500,
        data: null,
        message: 'Error updating pago estado: $e',
      );
    }
  }

  Future<ResponseModel> updatePagoBlockchain(int id, String blockchainId) async {
    try {
      ResponseModel response = await apiService.put('pagos/$id/blockchain', {'blockchain_id': blockchainId});
      print('Response from updatePagoBlockchain: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error updating pago blockchain: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error updating pago blockchain: $e',
        statusCode: 500,
        data: null,
        message: 'Error updating pago blockchain: $e',
      );
    }
  }

  Future<ResponseModel> getPagosPendientesByPropietarioId(int propietarioId) async {
    try {
      ResponseModel response = await apiService.get('pagos/pendientes/propietario/$propietarioId');
      print('Response from getPagosPendientesByPropietarioId: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error fetching pagos pendientes by propietario id: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error fetching pagos pendientes by propietario id: $e',
        statusCode: 500,
        data: null,
        message: 'Error fetching pagos pendientes by propietario id: $e',
      );
    }
  }

  Future<ResponseModel> getPagosCompletadosByPropietarioId(int propietarioId) async {
    try {
      ResponseModel response = await apiService.get('pagos/completados/propietario/$propietarioId');
      print('Response from getPagosCompletadosByPropietarioId: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error fetching pagos completados by propietario id: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error fetching pagos completados by propietario id: $e',
        statusCode: 500,
        data: null,
        message: 'Error fetching pagos completados by propietario id: $e',
      );
    }
  }
}
