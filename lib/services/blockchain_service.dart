import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/contract_model.dart';

class BlockchainService {
  late Web3Client _web3client;
  late String _rpcUrl;
  late EthPrivateKey _credentials;
  late String _contractAddress;
  late DeployedContract _contract;

  // Convert bytes to hexadecimal string
  String bytesToHex(Uint8List bytes) {
    return '0x${bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('')}';
  }

  // Smart contract ABI (Application Binary Interface)
  // This is a simplified ABI for demonstration purposes
  final String _abiCode = '''
  [
    {
      "inputs": [
        {"name": "propertyId", "type": "string"},
        {"name": "ownerId", "type": "string"},
        {"name": "renterId", "type": "string"},
        {"name": "startDate", "type": "uint256"},
        {"name": "endDate", "type": "uint256"},
        {"name": "monthlyRent", "type": "uint256"},
        {"name": "securityDeposit", "type": "uint256"}
      ],
      "name": "createRentalContract",
      "outputs": [{"name": "", "type": "uint256"}],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"name": "contractId", "type": "uint256"}],
      "name": "signContractAsOwner",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"name": "contractId", "type": "uint256"}],
      "name": "signContractAsRenter",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"name": "contractId", "type": "uint256"}],
      "name": "terminateContract",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"name": "contractId", "type": "uint256"}],
      "name": "getContractDetails",
      "outputs": [
        {"name": "propertyId", "type": "string"},
        {"name": "ownerId", "type": "string"},
        {"name": "renterId", "type": "string"},
        {"name": "startDate", "type": "uint256"},
        {"name": "endDate", "type": "uint256"},
        {"name": "monthlyRent", "type": "uint256"},
        {"name": "securityDeposit", "type": "uint256"},
        {"name": "isOwnerSigned", "type": "bool"},
        {"name": "isRenterSigned", "type": "bool"},
        {"name": "isActive", "type": "bool"}
      ],
      "stateMutability": "view",
      "type": "function"
    }
  ]
  ''';

  // Initialize the blockchain service
  Future<void> initialize() async {
    // For demonstration, we're using the Ethereum Goerli testnet
    // In a production app, you would use a mainnet or a more appropriate network
    _rpcUrl = 'https://goerli.infura.io/v3/your-infura-project-id';
    _web3client = Web3Client(_rpcUrl, Client());

    // Load or generate private key
    await _loadCredentials();

    // Load contract address
    await _loadContractAddress();

    // Initialize contract
    await _initializeContract();
  }

  // Load or generate Ethereum credentials
  Future<void> _loadCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? privateKey = prefs.getString('ethereum_private_key');

    if (privateKey == null) {
      // Generate a new private key if none exists
      _credentials = EthPrivateKey.createRandom(Random.secure());
      await prefs.setString('ethereum_private_key', bytesToHex(_credentials.privateKey));
    } else {
      // Load existing private key
      _credentials = EthPrivateKey.fromHex(privateKey);
    }
  }

  // Load contract address from storage or deploy a new contract
  Future<void> _loadContractAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? contractAddress = prefs.getString('rental_contract_address');

    if (contractAddress == null) {
      // In a real app, you would deploy the contract here
      // For demonstration, we'll use a placeholder address
      _contractAddress = '0x0000000000000000000000000000000000000000';
      await prefs.setString('rental_contract_address', _contractAddress);
    } else {
      _contractAddress = contractAddress;
    }
  }

  // Initialize the smart contract
  Future<void> _initializeContract() async {
    // Parse the ABI
    final contractAbi = ContractAbi.fromJson(_abiCode, 'RentalContract');
    // Create a DeployedContract instance
    _contract = DeployedContract(
      contractAbi,
      EthereumAddress.fromHex(_contractAddress),
    );
  }

  // Create a new rental contract on the blockchain
  Future<String?> createRentalContract(ContractModel contract) async {
    try {
      // Convert dates to Unix timestamps
      final startDateTimestamp = BigInt.from(contract.startDate.millisecondsSinceEpoch ~/ 1000);
      final endDateTimestamp = BigInt.from(contract.endDate.millisecondsSinceEpoch ~/ 1000);

      // Convert monetary values to wei (smallest Ethereum unit)
      final monthlyRentWei = BigInt.from(contract.monthlyRent * 1e18);
      final securityDepositWei = BigInt.from(contract.securityDeposit * 1e18);

      // Get the contract function
      final createFunction = _contract.function('createRentalContract');

      // Call the function
      final result = await _web3client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: createFunction,
          parameters: [
            contract.propertyId,
            contract.ownerId,
            contract.renterId,
            startDateTimestamp,
            endDateTimestamp,
            monthlyRentWei,
            securityDepositWei,
          ],
        ),
        chainId: 5, // Goerli testnet chain ID
      );

      return result;
    } catch (e) {
      print('Error creating rental contract on blockchain: $e');
      return null;
    }
  }

  // Sign a contract as the property owner
  Future<bool> signContractAsOwner(String contractId) async {
    try {
      final signFunction = _contract.function('signContractAsOwner');

      await _web3client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: signFunction,
          parameters: [BigInt.parse(contractId)],
        ),
        chainId: 5,
      );

      return true;
    } catch (e) {
      print('Error signing contract as owner: $e');
      return false;
    }
  }

  // Sign a contract as the renter
  Future<bool> signContractAsRenter(String contractId) async {
    try {
      final signFunction = _contract.function('signContractAsRenter');

      await _web3client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: signFunction,
          parameters: [BigInt.parse(contractId)],
        ),
        chainId: 5,
      );

      return true;
    } catch (e) {
      print('Error signing contract as renter: $e');
      return false;
    }
  }

  // Terminate a contract
  Future<bool> terminateContract(String contractId) async {
    try {
      final terminateFunction = _contract.function('terminateContract');

      await _web3client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: terminateFunction,
          parameters: [BigInt.parse(contractId)],
        ),
        chainId: 5,
      );

      return true;
    } catch (e) {
      print('Error terminating contract: $e');
      return false;
    }
  }

  // Get contract details from the blockchain
  Future<Map<String, dynamic>?> getContractDetails(String contractId) async {
    try {
      final getDetailsFunction = _contract.function('getContractDetails');

      final result = await _web3client.call(
        contract: _contract,
        function: getDetailsFunction,
        params: [BigInt.parse(contractId)],
      );

      if (result.isEmpty) return null;

      return {
        'propertyId': result[0],
        'ownerId': result[1],
        'renterId': result[2],
        'startDate': DateTime.fromMillisecondsSinceEpoch((result[3] as BigInt).toInt() * 1000),
        'endDate': DateTime.fromMillisecondsSinceEpoch((result[4] as BigInt).toInt() * 1000),
        'monthlyRent': (result[5] as BigInt).toDouble() / 1e18,
        'securityDeposit': (result[6] as BigInt).toDouble() / 1e18,
        'isOwnerSigned': result[7],
        'isRenterSigned': result[8],
        'isActive': result[9],
      };
    } catch (e) {
      print('Error getting contract details: $e');
      return null;
    }
  }

  // Get the user's Ethereum address
  String get ethereumAddress => _credentials.address.hex;

  // Get the user's Ethereum balance
  Future<double> getBalance() async {
    final balance = await _web3client.getBalance(_credentials.address);
    return balance.getValueInUnit(EtherUnit.ether);
  }
}
