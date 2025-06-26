import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:hex/hex.dart';
import '../models/contrato_model.dart';

class BlockchainService {
  static final BlockchainService _instance = BlockchainService._internal();

  // Ethereum client
  late Web3Client _client;

  // Contract details
  late DeployedContract _contract;
  late ContractFunction _createContract;
  late ContractFunction _approveContract;
  late ContractFunction _makePayment;
  late ContractFunction _getContractDetails;

  // Ethereum credentials
  late Credentials _credentials;

  // Network details
  late String _rpcUrl;
  late int _chainId;

  // Private constructor
  BlockchainService._internal();

  // Singleton pattern
  factory BlockchainService() {
    return _instance;
  }

  // Initialize the blockchain service
  Future<void> initialize({required String rpcUrl, required String privateKey, required int chainId}) async {
    _rpcUrl = rpcUrl;
    _chainId = chainId;

    // Initialize Ethereum client
    _client = Web3Client(_rpcUrl, Client());

    // Load contract ABI
    final contractABI = await rootBundle.loadString(
      'assets/rentals/build/contracts/RentalContract.json',
    );
    final contractAddress = EthereumAddress.fromHex(
      '0x9fa02580Bd718D5ad6e2f873148C9414C0962F40',
    ); // Replace with actual deployed address

    // Check if privateKey is a mnemonic phrase or a hex private key
    String hexPrivateKey;
    if (privateKey.contains(' ')) {
      // It's a mnemonic phrase, validate and convert to private key
      try {
        // Validate mnemonic phrase
        if (!bip39.validateMnemonic(privateKey)) {
          throw FormatException('Invalid mnemonic phrase. Please check for typos or incorrect words.');
        }

        // Generate seed from mnemonic
        final seed = bip39.mnemonicToSeedHex(privateKey);
        // Use the first 32 bytes (64 hex chars) as the private key
        hexPrivateKey = seed.substring(0, 64);

        print('Successfully converted mnemonic to private key');
      } catch (e) {
        if (e is FormatException) {
          throw e; // Re-throw our custom format exception
        }
        // Check for common issues in the mnemonic
        if (privateKey.contains('carck')) {
          throw FormatException('Invalid mnemonic phrase: "carck" should be "crack". Please correct the typo.');
        }
        throw FormatException('Error processing mnemonic phrase: $e. Please ensure it is a valid BIP39 mnemonic.');
      }
    } else {
      // It's already a hex private key
      if (!_isValidHex(privateKey)) {
        throw FormatException('Invalid hex private key. It must be a valid hexadecimal string.');
      }
      hexPrivateKey = privateKey;
    }

    // Create credentials from private key
    _credentials = EthPrivateKey.fromHex(hexPrivateKey);

    // Load contract
    final contractData = jsonDecode(contractABI);
    _contract = DeployedContract(
      ContractAbi.fromJson(jsonEncode(contractData['abi']), 'RentalContract'),
      contractAddress,
    );

    // Get contract functions
    _createContract = _contract.function('createContract');
    _approveContract = _contract.function('approveContract');
    _makePayment = _contract.function('makePayment');
    _getContractDetails = _contract.function('getContractDetails');
  }

  // Deploy the contract to the blockchain
  Future<String> deployContract() async {
    // Load contract bytecode
    final contractBytecode = await rootBundle.loadString(
      'assets/contracts/RentalContract.bin',
    );
    final contractABI = await rootBundle.loadString(
      'assets/contracts/RentalContract.json',
    );

    final contractData = jsonDecode(contractABI);
    final abi = ContractAbi.fromJson(
      jsonEncode(contractData['abi']),
      'RentalContract',
    );

    Uint8List hexToBytes(String hex) {
      hex = hex.replaceAll('0x', '');
      final length = hex.length ~/ 2;
      final bytes = Uint8List(length);
      for (int i = 0; i < length; i++) {
        bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
      }
      return bytes;
    }

    // Deploy contract
    final deployTransaction = Transaction.callContract(
      contract: DeployedContract(abi, EthereumAddress.fromHex('0x0')),
      function: ContractFunction(
        'deploy',
        [],
      ), // Ajusta el nombre de la función
      parameters: [],
    );

    // Send transaction
    final txHash = await _client.sendTransaction(
      _credentials,
      deployTransaction,
      chainId: _chainId,
    );

    // Wait for transaction receipt to get contract address
    final receipt = await _client.getTransactionReceipt(txHash);
    final contractAddress = receipt?.contractAddress?.hex;

    return contractAddress ?? '';
  }

  // Create a new rental contract on the blockchain
  Future<Map<String, String>> createRentalContract(
    ContratoModel contrato,
    String landlordAddress,
    String tenantAddress,
  ) async {
    try{
      print('Creating rental contract for property ID: ${contrato.inmuebleId}');
      // Convert contract data to blockchain format
      final contractId = BigInt.from(contrato.id);
      final propertyId = BigInt.from(contrato.inmuebleId);
      final rentAmount = BigInt.from(
        (contrato.monto * 1e18).toInt(),
      ); // Convert to wei
      final depositAmount = BigInt.from(
        (contrato.monto * 1e18).toInt(),
      ); // Use same amount for deposit
      final startDate = BigInt.from(
        contrato.fechaInicio.millisecondsSinceEpoch ~/ 1000,
      );
      final endDate = BigInt.from(
        contrato.fechaFin.millisecondsSinceEpoch ~/ 1000,
      );
      final termsHash = 'ipfs://QmHash'; // Replace with actual IPFS hash if available

      // Create transaction
      final transaction = Transaction.callContract(
        contract: _contract,
        function: _createContract,
        parameters: [
          contractId,
          EthereumAddress.fromHex('0x0000000000000000000000000000000000000001'),
          EthereumAddress.fromHex('0x0000000000000000000000000000000000000002'),
          propertyId,
          rentAmount,
          depositAmount,
          startDate,
          endDate,
          termsHash,
        ],
      );

      // Send transaction
      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: _chainId,
      );

      // Wait for transaction receipt to get contract address
      final receipt = await _client.getTransactionReceipt(txHash);
      final contractAddress = receipt?.contractAddress?.hex ?? '';

      return {
        'txHash': txHash,
        'contractAddress': contractAddress,
      };
    }catch (e) {
      print('Error creating rental contract: $e');
      throw Exception('Failed to create rental contract: $e');
    }
  }

  // Approve a contract on the blockchain
  Future<Map<String, String>> approveContract(int contractId) async {
    final transaction = Transaction.callContract(
      contract: _contract,
      function: _approveContract,
      parameters: [BigInt.from(contractId)],
    );

    final txHash = await _client.sendTransaction(
      _credentials,
      transaction,
      chainId: _chainId,
    );

    // Wait for transaction receipt
    final receipt = await _client.getTransactionReceipt(txHash);

    return {
      'txHash': txHash,
      'status': receipt?.status == 1 ? 'success' : 'failed',
    };
  }

  // Make a payment for a contract
  Future<Map<String, String>> makePayment(int contractId, double amount) async {
    final amountInWei = BigInt.from((amount * 1e18).toInt());

    final transaction = Transaction.callContract(
      contract: _contract,
      function: _makePayment,
      parameters: [BigInt.from(contractId)],
      value: EtherAmount.inWei(amountInWei),
    );

    final txHash = await _client.sendTransaction(
      _credentials,
      transaction,
      chainId: _chainId,
    );

    // Wait for transaction receipt
    final receipt = await _client.getTransactionReceipt(txHash);

    return {
      'txHash': txHash,
      'status': receipt?.status == 1 ? 'success' : 'failed',
      'amount': amount.toString(),
    };
  }

  // Get contract details from the blockchain
  Future<Map<String, dynamic>> getContractDetails(int contractId) async {
    final result = await _client.call(
      contract: _contract,
      function: _getContractDetails,
      params: [BigInt.from(contractId)],
    );

    if (result.isEmpty) {
      throw Exception('Contract not found');
    }

    return {
      'landlord': (result[0] as EthereumAddress).hex,
      'tenant': (result[1] as EthereumAddress).hex,
      'propertyId': (result[2] as BigInt).toInt(),
      'rentAmount': (result[3] as BigInt).toDouble() / 1e18,
      'depositAmount': (result[4] as BigInt).toDouble() / 1e18,
      'startDate': DateTime.fromMillisecondsSinceEpoch(
        (result[5] as BigInt).toInt() * 1000,
      ),
      'endDate': DateTime.fromMillisecondsSinceEpoch(
        (result[6] as BigInt).toInt() * 1000,
      ),
      'lastPaymentDate':
          (result[7] as BigInt).toInt() > 0
              ? DateTime.fromMillisecondsSinceEpoch(
                (result[7] as BigInt).toInt() * 1000,
              )
              : null,
      'state': (result[8] as BigInt).toInt(),
      'termsHash': result[9] as String,
    };
  }

  // Convert contract state from int to string
  String getContractStateString(int state) {
    switch (state) {
      case 0:
        return 'pendiente';
      case 1:
        return 'aprobado';
      case 2:
        return 'activo';
      case 3:
        return 'termination';
      case 4:
        return 'expirado';
      default:
        return 'desconocido';
    }
  }

  // Helper method to validate hex strings
  bool _isValidHex(String hex) {
    // Remove '0x' prefix if present
    if (hex.startsWith('0x')) {
      hex = hex.substring(2);
    }

    // Check if the string contains only hex characters and has even length
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex) && hex.length % 2 == 0;
  }

  // Get the wallet address from the credentials
  String getWalletAddress() {
    if (_credentials is EthPrivateKey) {
      final address = (_credentials as EthPrivateKey).address.hex;
      return address;
    }
    throw Exception('Credentials not initialized or not EthPrivateKey');
  }

  // Dispose resources
  void dispose() {
    _client.dispose();
  }
}
