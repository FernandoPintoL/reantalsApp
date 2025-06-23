import 'package:flutter/material.dart';
import '../blockchain/blockchain_service.dart';
import '../models/contrato_model.dart';
import '../models/user_model.dart';

class BlockchainProvider extends ChangeNotifier {
  final BlockchainService _blockchainService = BlockchainService();
  
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _message;
  String? _contractAddress;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get message => _message;
  String? get contractAddress => _contractAddress;
  
  // Initialize the blockchain service
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
  
  // Deploy the smart contract
  Future<String?> deploySmartContract() async {
    if (!_isInitialized) {
      _message = 'El servicio blockchain no está inicializado';
      notifyListeners();
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
  Future<bool> createRentalContract(ContratoModel contrato, UserModel propietario, UserModel cliente) async {
    if (!_isInitialized) {
      _message = 'El servicio blockchain no está inicializado';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _message = 'Creando contrato en blockchain...';
    notifyListeners();
    
    try {
      // Check if users have wallet addresses
      final landlordAddress = propietario.walletAddress;
      final tenantAddress = cliente.walletAddress;
      
      if (landlordAddress == null || landlordAddress.isEmpty) {
        _message = 'El propietario no tiene una dirección de wallet configurada';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      if (tenantAddress == null || tenantAddress.isEmpty) {
        _message = 'El cliente no tiene una dirección de wallet configurada';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Create contract on blockchain
      final txHash = await _blockchainService.createRentalContract(
        contrato, 
        landlordAddress, 
        tenantAddress
      );
      
      _message = 'Contrato creado en blockchain. Transaction hash: $txHash';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _message = 'Error al crear el contrato en blockchain: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Approve a contract on the blockchain
  Future<bool> approveContract(int contractId) async {
    if (!_isInitialized) {
      _message = 'El servicio blockchain no está inicializado';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _message = 'Aprobando contrato en blockchain...';
    notifyListeners();
    
    try {
      final txHash = await _blockchainService.approveContract(contractId);
      
      _message = 'Contrato aprobado en blockchain. Transaction hash: $txHash';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _message = 'Error al aprobar el contrato en blockchain: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Make a payment for a contract
  Future<bool> makePayment(int contractId, double amount) async {
    if (!_isInitialized) {
      _message = 'El servicio blockchain no está inicializado';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _message = 'Realizando pago en blockchain...';
    notifyListeners();
    
    try {
      final txHash = await _blockchainService.makePayment(contractId, amount);
      
      _message = 'Pago realizado en blockchain. Transaction hash: $txHash';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _message = 'Error al realizar el pago en blockchain: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Get contract details from the blockchain
  Future<Map<String, dynamic>?> getContractDetails(int contractId) async {
    if (!_isInitialized) {
      _message = 'El servicio blockchain no está inicializado';
      notifyListeners();
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