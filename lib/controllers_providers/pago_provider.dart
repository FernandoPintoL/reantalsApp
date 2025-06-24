import 'package:flutter/material.dart';
import '../models/pago_model.dart';
import '../models/response_model.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';
import '../negocio/AuthenticatedNegocio.dart';
import '../negocio/PagoNegocio.dart';
import '../negocio/SessionNegocio.dart';
import '../negocio/UserNegocio.dart';
import '../vista/components/message_widget.dart';
import 'blockchain_provider.dart';

class PagoProvider extends ChangeNotifier {
  final BlockchainProvider _blockchainProvider = BlockchainProvider();
  final PagoNegocio _pagoNegocio = PagoNegocio();
  final AuthenticatedNegocio _authenticatedNegocio = AuthenticatedNegocio();

  List<PagoModel> _pagos = [];
  List<PagoModel> _pagosContrato = [];
  List<PagoModel> _pagosPendientesCliente = [];
  List<PagoModel> _pagosCompletadosCliente = [];
  List<PagoModel> _pagosPendientesPropietario = [];
  bool _isLoading = false;
  String? _message;
  UserModel? _currentUser;
  MessageType _messageType = MessageType.info;

  PagoProvider() {
    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    try {
      isLoading = true;
      currentUser = await _authenticatedNegocio.getUserSession();
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

  Future<bool> createPago(PagoModel pago) async {
    try {
      isLoading = true;
      if (_currentUser == null) {
        await loadCurrentUser();
        if (_currentUser == null) {
          message = 'No se pudo cargar el usuario actual';
          isLoading = false;
          return false;
        }
      }
      ResponseModel response = await _pagoNegocio.createPago(pago);
      if (response.isSuccess && response.data != null) {
        message = 'Pago creado exitosamente';
        // Create payment on blockchain if service is initialized
        if (_blockchainProvider.isInitialized) {
          try {
            final blockchainSuccess = await _blockchainProvider.makePayment(pago.contratoId, pago.monto);
            if (blockchainSuccess) {
              message = '$message y procesado en blockchain';
              // Get blockchain transaction ID and update payment
              final blockchainDetails = await _blockchainProvider.getContractDetails(pago.contratoId);
              if (blockchainDetails != null && blockchainDetails.containsKey('transactionHash')) {
                final blockchainId = blockchainDetails['transactionHash'];
                await _pagoNegocio.updatePagoBlockchain(pago.id, blockchainId);
              }
            }
          } catch (blockchainError) {
            // Don't fail the entire operation if blockchain fails
            print('Error processing payment on blockchain: $blockchainError');
          }
        }
        // Refresh the list
        await loadPagosByClienteId();
        isLoading = false;
        return true;
      } else {
        message = response.messageError ?? 'Error al crear el pago';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al crear el pago: $e';
      isLoading = false;
      return false;
    }
  }

  Future<void> loadPagosContratoId(int contratoId) async {
    try {
      isLoading = true;
      ResponseModel response = await _pagoNegocio.getPagosContratoId(contratoId);
      if (response.isSuccess && response.data != null) {
        pagosContrato = PagoModel.fromList(response.data);
        message = null; // Reset message on successful load
      } else {
        message = response.messageError ?? 'No se encontraron pagos para este contrato';
      }
    } catch (e) {
      message = 'Error al cargar los pagos del contrato: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadPagosPendientesCliente() async {
    if (currentUser == null) {
      message = 'No se pudo cargar el usuario actual';
      return;
    }
    try {
      isLoading = true;
      ResponseModel response = await _pagoNegocio.getPagosPendientesByClienteId(currentUser!.id);
      if (response.isSuccess && response.data != null) {
        pagosPendientesCliente = PagoModel.fromList(response.data);
        message = null; // Reset message on successful load
      } else {
        message = response.messageError ?? 'No se encontraron pagos pendientes para este usuario';
      }
    } catch (e) {
      message = 'Error al cargar los pagos pendientes del usuario: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadPagosCompletadosCliente() async {
    if (currentUser == null) {
      await loadCurrentUser();
      if (currentUser == null) {
        message = 'No se pudo cargar el usuario actual';
        return;
      }
    }
    try {
      isLoading = true;
      ResponseModel response = await _pagoNegocio.getPagosCompletadosByClienteId(currentUser!.id);
      if (response.isSuccess && response.data != null) {
        pagosCompletadosCliente = PagoModel.fromList(response.data);
        message = null; // Reset message on successful load
      } else {
        message = response.messageError ?? 'No se encontraron pagos completados para este usuario';
      }
    } catch (e) {
      message = 'Error al cargar los pagos completados del usuario: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadPagosByClienteId() async {
    if (_currentUser == null) {
      await loadCurrentUser();
      if (_currentUser == null) {
        message = 'No se pudo cargar el usuario actual';
        return;
      }
    }
    try {
      isLoading = true;
      ResponseModel response = await _pagoNegocio.getPagosByClienteId(_currentUser!.id);
      if (response.isSuccess && response.data != null) {
        pagos = PagoModel.fromList(response.data);
        message = null; // Reset message on successful load
      } else {
        message = response.messageError ?? 'No se encontraron pagos para este usuario';
      }
    } catch (e) {
      message = 'Error al cargar los pagos del usuario: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<bool> updatePagoEstado(int id, String estado) async {
    try {
      isLoading = true;
      ResponseModel response = await _pagoNegocio.updatePagoEstado(id, estado);
      if (response.isSuccess) {
        message = 'Estado del pago actualizado exitosamente';
        // Refresh the list
        await loadPagosByClienteId();
        isLoading = false;
        return true;
      } else {
        message = response.messageError ?? 'Error al actualizar el estado del pago';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al actualizar el estado del pago: $e';
      isLoading = false;
      return false;
    }
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

  List<PagoModel> get pagos => _pagos;

  set pagos(List<PagoModel> value) {
    _pagos = value;
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

  List<PagoModel> get pagosPendientesPropietario => _pagosPendientesPropietario;

  set pagosPendientesPropietario(List<PagoModel> value) {
    _pagosPendientesPropietario = value;
    notifyListeners();
  }

  List<PagoModel> get pagosPendientesCliente => _pagosPendientesCliente;

  set pagosPendientesCliente(List<PagoModel> value) {
    _pagosPendientesCliente = value;
    notifyListeners();
  }

  List<PagoModel> get pagosCompletadosCliente => _pagosCompletadosCliente;
  set pagosCompletadosCliente(List<PagoModel> value) {
    _pagosCompletadosCliente = value;
    notifyListeners();
  }
  List<PagoModel> get pagosContrato => _pagosContrato;
  set pagosContrato(List<PagoModel> value) {
    _pagosContrato = value;
    notifyListeners();
  }
}