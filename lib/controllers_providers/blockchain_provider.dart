import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../blockchain/blockchain_service.dart';
import '../models/contrato_model.dart';
import '../models/user_model.dart';
import 'authenticated_provider.dart';
import 'user_global_provider.dart';

class BlockchainProvider extends ChangeNotifier {
  static BlockchainProvider? _instance;
  final BlockchainService _blockchainService = BlockchainService();
  final UserGlobalProvider _userGlobalProvider = UserGlobalProvider();
  final AuthenticatedProvider? _authenticatedProvider;

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _message;
  String? _contractAddress;

  // Singleton pattern to ensure we have only one instance
  static BlockchainProvider get instance {
    _instance ??= BlockchainProvider._internal();
    return _instance!;
  }

  // Private constructor for singleton
  BlockchainProvider._internal() : _authenticatedProvider = null;

  // Constructor with AuthenticatedProvider
  BlockchainProvider._withAuthProvider(AuthenticatedProvider authProvider) 
      : _authenticatedProvider = authProvider;

  // Public constructor for provider system
  factory BlockchainProvider({AuthenticatedProvider? authProvider}) {
    if (authProvider != null && _instance == null) {
      _instance = BlockchainProvider._withAuthProvider(authProvider);
    } else if (_instance == null) {
      _instance = BlockchainProvider._internal();
    }
    return _instance!;
  }

  // Method to update the user's wallet address
  Future<bool> updateUserWalletAddress() async {
    if (!_isInitialized) {
      await ensureInitialized();
    }

    try {
      // Get the wallet address from the blockchain service
      final walletAddress = _blockchainService.getWalletAddress();

      // Get the current user from the global provider
      final currentUser = _userGlobalProvider.currentUser;

      if (currentUser != null) {
        // Check if the wallet address has changed
        if (currentUser.walletAddress != walletAddress) {
          // Create a new user model with the updated wallet address
          final updatedUser = UserModel(
            id: currentUser.id,
            name: currentUser.name,
            email: currentUser.email,
            usernick: currentUser.usernick,
            numId: currentUser.numId,
            telefono: currentUser.telefono,
            direccion: currentUser.direccion,
            walletAddress: walletAddress,
            tipoUsuario: currentUser.tipoUsuario,
            tipoCliente: currentUser.tipoCliente,
            photoPath: currentUser.photoPath,
            createdAt: currentUser.createdAt,
            updatedAt: currentUser.updatedAt,
          );

          // Update the user in the global provider
          _userGlobalProvider.updateUser(updatedUser);

          // Update the user in the backend if authenticated provider is available
          if (_authenticatedProvider != null) {
            await _authenticatedProvider!.updateUserProfile(updatedUser);
          }

          _message = 'Wallet address updated: $walletAddress';
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      _message = 'Error updating wallet address: $e';
      notifyListeners();
      return false;
    }
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get message => _message;
  String? get contractAddress => _contractAddress;

  // Initialize the blockchain service with explicit parameters
  Future<bool> initialize({required String rpcUrl, required String privateKey, required int chainId}) async {
    _isLoading = true;
    _message = 'Inicializando servicio blockchain...';
    notifyListeners();

    try {
      await _blockchainService.initialize(
        rpcUrl: rpcUrl,
        privateKey: privateKey,
        chainId: chainId,
      );

      _isInitialized = true;
      _message = 'Servicio blockchain inicializado correctamente';

      // Update the user's wallet address
      await updateUserWalletAddress();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _message = 'Error al inicializar el servicio blockchain: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Initialize the blockchain service with default parameters from .env
  Future<bool> initializeFromEnv() async {
    // Get blockchain configuration from .env
    final rpcUrl = dotenv.env['BLOCKCHAIN_RPC_URL_LOCAL'] ?? '';
    final privateKey = dotenv.env['MEMONIC'] ?? '';
    final chainId = 1337;

    if (rpcUrl.isEmpty || privateKey.isEmpty || chainId == 0) {
      _message = 'Configuración blockchain incompleta en .env';
      notifyListeners();
      return false;
    }

    // Initialize the blockchain service
    bool success = await initialize(
      rpcUrl: rpcUrl,
      privateKey: privateKey,
      chainId: chainId,
    );

    return success;
  }

  // Ensure blockchain is initialized before any operation
  Future<bool> ensureInitialized() async {
    if (_isInitialized) return true;
    return await initializeFromEnv();
  }

  // Deploy the smart contract
  Future<String?> deploySmartContract() async {
    // Ensure blockchain is initialized
    if (!await ensureInitialized()) {
      return null;
    }

    _isLoading = true;
    _message = 'Desplegando smart contract...';
    notifyListeners();

    try {
      final address = await _blockchainService.deployContract();
      _contractAddress = address;
      _message = 'Smart contract desplegado correctamente en: $address';
      _isLoading = false;
      notifyListeners();
      return address;
    } catch (e) {
      _message = 'Error al desplegar el smart contract: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Create a rental contract on the blockchain
  Future<Map<String, String>?> createRentalContract(ContratoModel contrato, UserModel propietario, UserModel cliente) async {
    print('Creating rental contract on blockchain...');
    // Ensure blockchain is initialized
    if (!await ensureInitialized()) {
      print('Blockchain not initialized');
      return null;
    }

    _isLoading = true;
    _message = 'Creando contrato en blockchain...';
    notifyListeners();

    try {
      // Check if users have wallet addresses
      final landlordAddress = '0x0000000000000000000000000000000000000001';
      print('Landlord wallet address: $landlordAddress');
      final tenantAddress = '0x0000000000000000000000000000000000000002';
      print('Tenant wallet address: $tenantAddress');

      /*if (landlordAddress == null || landlordAddress.isEmpty) {
        _message = 'El propietario no tiene una dirección de wallet configurada';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      if (tenantAddress == null || tenantAddress.isEmpty) {
        _message = 'El cliente no tiene una dirección de wallet configurada';
        print('Tenant wallet address is empty');
        _isLoading = false;
        notifyListeners();
        return null;
      }*/

      // Create contract on blockchain
      final result = await _blockchainService.createRentalContract(
        contrato, 
        landlordAddress, 
        tenantAddress
      );
      print('Blockchain contract creation result: $result');

      _message = 'Contrato creado en blockchain. Transaction hash: ${result['txHash']}';
      print('Blockchain contract creation result: $result');
      if (result['contractAddress'] != null && result['contractAddress']!.isNotEmpty) {
        _message = '$_message, Contract address: ${result['contractAddress']}';
        print('Contract address: ${result['contractAddress']}');
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _message = 'Error al crear el contrato en blockchain: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Approve a contract on the blockchain
  Future<Map<String, String>?> approveContract(int contractId) async {
    // Ensure blockchain is initialized
    if (!await ensureInitialized()) {
      return null;
    }

    _isLoading = true;
    _message = 'Aprobando contrato en blockchain...';
    notifyListeners();

    try {
      final result = await _blockchainService.approveContract(contractId);

      _message = 'Contrato aprobado en blockchain. Transaction hash: ${result['txHash']}';
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _message = 'Error al aprobar el contrato en blockchain: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Make a payment for a contract
  Future<Map<String, String>?> makePayment(int contractId, double amount) async {
    // Ensure blockchain is initialized
    if (!await ensureInitialized()) {
      return null;
    }

    _isLoading = true;
    _message = 'Realizando pago en blockchain...';
    notifyListeners();

    try {
      final result = await _blockchainService.makePayment(contractId, amount);

      _message = 'Pago realizado en blockchain. Transaction hash: ${result['txHash']}';
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _message = 'Error al realizar el pago en blockchain: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Get contract details from the blockchain
  Future<Map<String, dynamic>?> getContractDetails(int contractId) async {
    // Ensure blockchain is initialized
    if (!await ensureInitialized()) {
      return null;
    }

    _isLoading = true;
    _message = 'Obteniendo detalles del contrato desde blockchain...';
    notifyListeners();

    try {
      final details = await _blockchainService.getContractDetails(contractId);

      _message = 'Detalles del contrato obtenidos correctamente';
      _isLoading = false;
      notifyListeners();
      return details;
    } catch (e) {
      _message = 'Error al obtener detalles del contrato: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Set message
  set message(String? value) {
    _message = value;
    notifyListeners();
  }

  // Set loading state
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Dispose resources
  @override
  void dispose() {
    _blockchainService.dispose();
    super.dispose();
  }
}
