import 'package:flutter/material.dart';
import '../models/pago_model.dart';
import '../models/response_model.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';
import '../negocio/PagoNegocio.dart';
import '../negocio/SessionNegocio.dart';
import '../negocio/UserNegocio.dart';
import 'blockchain_provider.dart';

class PagoProvider extends ChangeNotifier {
  final BlockchainProvider _blockchainProvider = BlockchainProvider();
  final PagoNegocio _pagoNegocio = PagoNegocio();
  final SessionNegocio _sessionNegocio = SessionNegocio();
  final UserNegocio _userNegocio = UserNegocio();
  SessionModelo? _sessionModel;

  List<PagoModel> _pagos = [];
  bool _isLoading = false;
  String? _message;
  UserModel? _currentUser;

  PagoProvider() {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      _sessionModel = await _sessionNegocio.getSession();
      if (_sessionModel != null && _sessionModel!.userId != null) {
        _currentUser = await _userNegocio.getUser(_sessionModel!.userId!);
      } else {
        _currentUser = null;
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<bool> createPago(PagoModel pago) async {
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
        await loadPagosByUserId();

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

  Future<void> loadPagosByContratoId(int contratoId) async {
    _isLoading = true;
    notifyListeners();

    try {
      ResponseModel response = await _pagoNegocio.getPagosByContratoId(contratoId);

      if (response.isSuccess && response.data != null) {
        pagos = PagoModel.fromList(response.data);
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

  Future<void> loadPagosByUserId() async {
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
      ResponseModel response = await _pagoNegocio.getPagosByUserId(_currentUser!.id);

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
    _isLoading = true;
    notifyListeners();

    try {
      ResponseModel response = await _pagoNegocio.updatePagoEstado(id, estado);

      if (response.isSuccess) {
        message = 'Estado del pago actualizado exitosamente';

        // Refresh the list
        await loadPagosByUserId();

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
}