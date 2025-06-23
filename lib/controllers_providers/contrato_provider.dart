import 'package:flutter/material.dart';
import '../models/contrato_model.dart';
import '../models/response_model.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';
import '../models/solicitud_alquiler_model.dart';
import '../negocio/ContratoNegocio.dart';
import '../negocio/SessionNegocio.dart';
import '../negocio/SolicitudAlquilerNegocio.dart';
import '../negocio/UserNegocio.dart';
import 'blockchain_provider.dart';

class ContratoProvider extends ChangeNotifier {
  final BlockchainProvider _blockchainProvider = BlockchainProvider();
  final ContratoNegocio _contratoNegocio = ContratoNegocio();
  final SolicitudAlquilerNegocio _solicitudNegocio = SolicitudAlquilerNegocio();
  final SessionNegocio _sessionNegocio = SessionNegocio();
  final UserNegocio _userNegocio = UserNegocio();
  SessionModelo? _sessionModel;

  List<ContratoModel> _contratos = [];
  ContratoModel? _selectedContrato;
  bool _isLoading = false;
  String? _message;
  UserModel? _currentUser;

  ContratoProvider() {
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

  Future<bool> createContrato(ContratoModel contrato) async {
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

      ResponseModel response = await _contratoNegocio.createContrato(contrato);

      if (response.isSuccess && response.data != null) {
        _selectedContrato = ContratoModel.fromMap(response.data);
        message = 'Contrato creado exitosamente';

        // If this contract is associated with a solicitud, update its status
        if (contrato.solicitudId != null) {
          await _solicitudNegocio.updateSolicitudEstado(contrato.solicitudId!, 'contrato_generado');
        }

        // Create contract on blockchain if both users have wallet addresses
        if (_blockchainProvider.isInitialized && contrato.cliente != null && contrato.inmueble?.userId != null) {
          try {
            UserModel? propietario = await _userNegocio.getUser(contrato.inmueble!.userId);
            final blockchainSuccess = await _blockchainProvider.createRentalContract(
              _selectedContrato!,
              propietario!,
              contrato.cliente!
            );

            if (blockchainSuccess) {
              message = '$message y registrado en blockchain';
            }
          } catch (blockchainError) {
            // Don't fail the entire operation if blockchain fails
            print('Error creating contract on blockchain: $blockchainError');
          }
        }

        await loadContratosByPropietarioId(); // Refresh the list
        isLoading = false;
        return true;
      } else {
        message = response.messageError ?? 'Error al crear el contrato';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al crear el contrato: $e';
      isLoading = false;
      return false;
    }
  }

  Future<bool> createContratoFromSolicitud(SolicitudAlquilerModel solicitud, 
      {required DateTime fechaInicio, 
       required DateTime fechaFin, 
       required double monto, 
       String? detalle, 
       List<CondicionalModel> condicionales = const []}) async {

    if (_currentUser == null) {
      await _loadCurrentUser();
      if (_currentUser == null) {
        message = 'No se pudo cargar el usuario actual';
        return false;
      }
    }

    // Create a new contract from the solicitud
    final contrato = ContratoModel(
      inmuebleId: solicitud.inmuebleId,
      userId: solicitud.userId,
      solicitudId: solicitud.id,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      monto: monto,
      detalle: detalle,
      estado: 'pendiente',
      condicionales: condicionales,
      clienteAprobado: false,
      solicitud: solicitud,
      inmueble: solicitud.inmueble,
      cliente: solicitud.cliente,
    );

    return await createContrato(contrato);
  }

  Future<void> loadContratosByUserId() async {
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
      ResponseModel response = await _contratoNegocio.getContratosByUserId(_currentUser!.id);

      if (response.isSuccess && response.data != null) {
        contratos = ContratoModel.fromJsonList(response.data);
        message = null; // Reset message on successful load
      } else {
        message = response.messageError ?? 'No se encontraron contratos para este usuario';
      }
    } catch (e) {
      message = 'Error al cargar los contratos del usuario: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadContratosByPropietarioId() async {
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
      ResponseModel response = await _contratoNegocio.getContratosByPropietarioId(_currentUser!.id);

      if (response.isSuccess && response.data != null) {
        contratos = ContratoModel.fromJsonList(response.data);
        message = null; // Reset message on successful load
      } else {
        message = response.messageError ?? 'No se encontraron contratos para este propietario';
      }
    } catch (e) {
      message = 'Error al cargar los contratos del propietario: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<bool> updateContratoEstado(int id, String estado) async {
    _isLoading = true;
    notifyListeners();

    try {
      ResponseModel response = await _contratoNegocio.updateContratoEstado(id, estado);

      if (response.isSuccess) {
        message = 'Estado del contrato actualizado exitosamente';

        // Refresh the list based on user type
        if (_currentUser?.tipoUsuario == 'propietario') {
          await loadContratosByPropietarioId();
        } else {
          await loadContratosByUserId();
        }

        isLoading = false;
        return true;
      } else {
        message = response.messageError ?? 'Error al actualizar el estado del contrato';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al actualizar el estado del contrato: $e';
      isLoading = false;
      return false;
    }
  }

  Future<bool> updateContratoClienteAprobado(int id, bool clienteAprobado) async {
    _isLoading = true;
    notifyListeners();

    try {
      ResponseModel response = await _contratoNegocio.updateContratoClienteAprobado(id, clienteAprobado);

      if (response.isSuccess) {
        message = clienteAprobado 
            ? 'Contrato aprobado exitosamente' 
            : 'Contrato rechazado exitosamente';

        // Update the contract status based on approval
        if (clienteAprobado) {
          await _contratoNegocio.updateContratoEstado(id, 'aprobado');

          // Approve contract on blockchain if service is initialized
          if (_blockchainProvider.isInitialized) {
            try {
              final blockchainSuccess = await _blockchainProvider.approveContract(id);
              if (blockchainSuccess) {
                message = '$message y actualizado en blockchain';
              }
            } catch (blockchainError) {
              // Don't fail the entire operation if blockchain fails
              print('Error approving contract on blockchain: $blockchainError');
            }
          }
        } else {
          await _contratoNegocio.updateContratoEstado(id, 'rechazado');
        }

        // Refresh the list
        await loadContratosByUserId();

        isLoading = false;
        return true;
      } else {
        message = response.messageError ?? 'Error al actualizar la aprobación del contrato';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al actualizar la aprobación del contrato: $e';
      isLoading = false;
      return false;
    }
  }

  Future<bool> registrarPagoContrato(int id, DateTime fechaPago) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get the contract to get the amount
      ContratoModel? contrato;
      for (var c in _contratos) {
        if (c.id == id) {
          contrato = c;
          break;
        }
      }

      if (contrato == null) {
        message = 'No se encontró el contrato';
        isLoading = false;
        return false;
      }

      ResponseModel response = await _contratoNegocio.updateContratoPago(id, fechaPago);

      if (response.isSuccess) {
        message = 'Pago registrado exitosamente';

        // Update the contract status to active
        await _contratoNegocio.updateContratoEstado(id, 'activo');

        // Make payment on blockchain if service is initialized
        if (_blockchainProvider.isInitialized) {
          try {
            final blockchainSuccess = await _blockchainProvider.makePayment(id, contrato.monto);
            if (blockchainSuccess) {
              message = '$message y procesado en blockchain';

              // Update blockchain address if payment was successful
              final blockchainDetails = await _blockchainProvider.getContractDetails(id);
              if (blockchainDetails != null && blockchainDetails.containsKey('landlord')) {
                final blockchainAddress = blockchainDetails['landlord'];
                await updateContratoBlockchain(id, blockchainAddress);
              }
            }
          } catch (blockchainError) {
            // Don't fail the entire operation if blockchain fails
            print('Error making payment on blockchain: $blockchainError');
          }
        }

        // Refresh the list
        await loadContratosByUserId();

        isLoading = false;
        return true;
      } else {
        message = response.messageError ?? 'Error al registrar el pago';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al registrar el pago: $e';
      isLoading = false;
      return false;
    }
  }

  Future<bool> updateContratoBlockchain(int id, String blockchainAddress) async {
    _isLoading = true;
    notifyListeners();

    try {
      ResponseModel response = await _contratoNegocio.updateContratoBlockchain(id, blockchainAddress);

      if (response.isSuccess) {
        message = 'Dirección blockchain actualizada exitosamente';

        // Refresh the list based on user type
        if (_currentUser?.tipoUsuario == 'propietario') {
          await loadContratosByPropietarioId();
        } else {
          await loadContratosByUserId();
        }

        isLoading = false;
        return true;
      } else {
        message = response.messageError ?? 'Error al actualizar la dirección blockchain';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al actualizar la dirección blockchain: $e';
      isLoading = false;
      return false;
    }
  }

  void selectContrato(ContratoModel contrato) {
    _selectedContrato = contrato;
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

  List<ContratoModel> get contratos => _contratos;

  set contratos(List<ContratoModel> value) {
    _contratos = value;
    notifyListeners();
  }

  ContratoModel? get selectedContrato => _selectedContrato;

  UserModel? get currentUser => _currentUser;
}
