import '../services/ApiService.dart';
import '../models/contrato_model.dart';
import '../models/response_model.dart';

class ContratoNegocio {
  final ApiService apiService;

  ContratoNegocio({ApiService? apiService}) : this.apiService = apiService ?? ApiService.getInstance();

  Future<ResponseModel> createContrato(ContratoModel contrato) async {
    try {
      ResponseModel response = await apiService.post('contratos/store', contrato.toMap());
      print('Response from createContrato: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error creating contrato: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error creating contrato: $e',
        statusCode: 500,
        data: null,
        message: 'Error creating contrato: $e',
      );
    }
  }

  Future<ResponseModel> getContratosByClienteId(int userId) async {
    try {
      ResponseModel response = await apiService.get('contratos/cliente/$userId');
      print('Response from getContratosByUserId: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error fetching contratos by user id: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error fetching contratos by user id: $e',
        statusCode: 500,
        data: null,
        message: 'Error fetching contratos by user id: $e',
      );
    }
  }

  Future<ResponseModel> getContratosByPropietarioId(int propietarioId) async {
    try {
      ResponseModel response = await apiService.get('contratos/propietario/$propietarioId');
      print('Response from getContratosByPropietarioId: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error fetching contratos by propietario id: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error fetching contratos by propietario id: $e',
        statusCode: 500,
        data: null,
        message: 'Error fetching contratos by propietario id: $e',
      );
    }
  }

  Future<ResponseModel> getContratoById(int id) async {
    try {
      ResponseModel response = await apiService.get('contratos/$id');
      print('Response from getContratoById: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error fetching contrato by id: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error fetching contrato by id: $e',
        statusCode: 500,
        data: null,
        message: 'Error fetching contrato by id: $e',
      );
    }
  }

  Future<ResponseModel> updateContratoEstado(int id, String estado) async {
    try {
      ResponseModel response = await apiService.put('contratos/$id/estado', {'estado': estado});
      print('Response from updateContratoEstado: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error updating contrato estado: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error updating contrato estado: $e',
        statusCode: 500,
        data: null,
        message: 'Error updating contrato estado: $e',
      );
    }
  }

  Future<ResponseModel> updateContratoClienteAprobado(int id, bool clienteAprobado) async {
    try {
      ResponseModel response = await apiService.put('contratos/$id/cliente-aprobado', {'cliente_aprobado': clienteAprobado});
      print('Response from updateContratoClienteAprobado: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error updating contrato cliente aprobado: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error updating contrato cliente aprobado: $e',
        statusCode: 500,
        data: null,
        message: 'Error updating contrato cliente aprobado: $e',
      );
    }
  }

  Future<ResponseModel> updateContratoFechaPago(int id, DateTime fechaPago) async {
    try {
      ResponseModel response = await apiService.put('contratos/$id/fecha-pago', {'fecha_pago': fechaPago.toIso8601String()});
      print('Response from updateContratoPago: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error updating contrato pago: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error updating contrato pago: $e',
        statusCode: 500,
        data: null,
        message: 'Error updating contrato pago: $e',
      );
    }
  }

  Future<ResponseModel> updateContratoBlockchain(int id, String blockchainAddress) async {
    try {
      ResponseModel response = await apiService.put('contratos/$id/blockchain', {'blockchain_address': blockchainAddress});
      print('Response from updateContratoBlockchain: ${response.toJson()}');
      return response;
    } catch (e) {
      print('Error updating contrato blockchain: $e');
      return ResponseModel(
        isRequest: false,
        isSuccess: false,
        isMessageError: true,
        messageError: 'Error updating contrato blockchain: $e',
        statusCode: 500,
        data: null,
        message: 'Error updating contrato blockchain: $e',
      );
    }
  }
}