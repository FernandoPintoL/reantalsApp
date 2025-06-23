# Guía de Implementación de Blockchain para la Aplicación de Alquileres

Esta guía proporciona instrucciones detalladas para implementar y conectar una blockchain local y en producción con la aplicación de alquileres.

## Índice

1. [Introducción](#introducción)
2. [Configuración del Entorno de Desarrollo](#configuración-del-entorno-de-desarrollo)
3. [Implementación Local con Ganache](#implementación-local-con-ganache)
4. [Implementación en Testnet (Sepolia)](#implementación-en-testnet-sepolia)
5. [Implementación en Producción (Ethereum Mainnet)](#implementación-en-producción-ethereum-mainnet)
6. [Integración con la Aplicación Flutter](#integración-con-la-aplicación-flutter)
7. [Pruebas y Verificación](#pruebas-y-verificación)
8. [Consideraciones de Seguridad](#consideraciones-de-seguridad)
9. [Optimización de Costos](#optimización-de-costos)
10. [Recursos Adicionales](#recursos-adicionales)

## Introducción

La aplicación de alquileres utiliza contratos inteligentes en Ethereum para gestionar contratos de alquiler y pagos de forma segura y transparente. Esta integración permite:

- Registro inmutable de contratos de alquiler
- Pagos automatizados y verificables
- Transparencia en las condiciones del contrato
- Reducción de disputas mediante la ejecución automática de términos contractuales

## Configuración del Entorno de Desarrollo

### Requisitos Previos

1. **Node.js y npm**: Instalar la última versión LTS desde [nodejs.org](https://nodejs.org/)
2. **Truffle Suite**: Framework para desarrollo de contratos inteligentes
   ```bash
   npm install -g truffle
   ```
3. **Ganache**: Blockchain local para desarrollo
   - Descargar desde [trufflesuite.com/ganache](https://trufflesuite.com/ganache)
4. **MetaMask**: Extensión de navegador para interactuar con la blockchain
   - Instalar desde [metamask.io](https://metamask.io/)
5. **Solidity Compiler**: Para compilar contratos inteligentes
   ```bash
   npm install -g solc
   ```

### Configuración del Proyecto

1. Crear una carpeta para los contratos inteligentes:
   ```bash
   mkdir -p assets/contracts
   ```

2. Copiar el contrato RentalContract.sol a la carpeta assets/contracts

3. Instalar dependencias para el desarrollo de contratos:
   ```bash
   npm init -y
   npm install @openzeppelin/contracts @truffle/hdwallet-provider dotenv web3
   ```

4. Crear un archivo truffle-config.js en la raíz del proyecto:
   ```javascript
   require('dotenv').config();
   const HDWalletProvider = require('@truffle/hdwallet-provider');

   module.exports = {
     networks: {
       development: {
         host: "127.0.0.1",
         port: 7545,
         network_id: "*",
       },
       sepolia: {
         provider: () => new HDWalletProvider(
           process.env.MNEMONIC,
           `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`
         ),
         network_id: 11155111,
         gas: 5500000,
         confirmations: 2,
         timeoutBlocks: 200,
         skipDryRun: true
       },
       mainnet: {
         provider: () => new HDWalletProvider(
           process.env.MNEMONIC,
           `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`
         ),
         network_id: 1,
         gas: 5500000,
         gasPrice: 20000000000,  // 20 Gwei
         confirmations: 2,
         timeoutBlocks: 200,
         skipDryRun: true
       }
     },
     compilers: {
       solc: {
         version: "0.8.17",
         settings: {
           optimizer: {
             enabled: true,
             runs: 200
           }
         }
       }
     }
   };
   ```

5. Crear un archivo .env en la raíz del proyecto:
   ```
   MNEMONIC="tu frase mnemónica de 12 palabras aquí"
   INFURA_API_KEY=tu_clave_api_de_infura
   ```

## Implementación Local con Ganache

### Configuración de Ganache

1. Iniciar Ganache y crear un nuevo workspace
2. Configurar el puerto a 7545
3. Añadir el archivo truffle-config.js al workspace
4. Guardar la configuración

### Compilación y Migración del Contrato

1. Crear un archivo de migración en la carpeta migrations:
   ```javascript
   // migrations/1_deploy_rental_contract.js
   const RentalContract = artifacts.require("RentalContract");

   module.exports = function(deployer) {
     deployer.deploy(RentalContract);
   };
   ```

2. Compilar el contrato:
   ```bash
   truffle compile
   ```

3. Migrar el contrato a Ganache:
   ```bash
   truffle migrate --network development
   ```

4. Guardar la dirección del contrato desplegado para usarla en la aplicación

### Configuración de MetaMask para Desarrollo Local

1. Abrir MetaMask y añadir una red personalizada:
   - Nombre de la red: Ganache Local
   - URL de RPC: http://127.0.0.1:7545
   - ID de cadena: 1337
   - Símbolo de moneda: ETH

2. Importar una cuenta de Ganache a MetaMask:
   - Copiar la clave privada de una cuenta de Ganache
   - En MetaMask, seleccionar "Importar cuenta" y pegar la clave privada

## Implementación en Testnet (Sepolia)

### Obtención de ETH de Prueba

1. Registrarse en [Infura](https://infura.io/) y crear un nuevo proyecto
2. Obtener ETH de prueba del grifo de Sepolia:
   - [Sepolia Faucet](https://sepoliafaucet.com/)
   - [Alchemy Sepolia Faucet](https://sepoliafaucet.com/)

### Despliegue en Sepolia

1. Asegurarse de que el archivo .env contiene la frase mnemónica y la clave API de Infura
2. Desplegar el contrato en Sepolia:
   ```bash
   truffle migrate --network sepolia
   ```

3. Verificar el contrato en [Sepolia Etherscan](https://sepolia.etherscan.io/):
   ```bash
   truffle run verify RentalContract --network sepolia
   ```

4. Guardar la dirección del contrato desplegado para usarla en la aplicación

## Implementación en Producción (Ethereum Mainnet)

### Consideraciones Previas

1. **Auditoría de Seguridad**: Antes de desplegar en mainnet, es altamente recomendable realizar una auditoría de seguridad del contrato inteligente.
2. **Costos de Gas**: Las transacciones en mainnet tienen un costo real. Optimizar el contrato para reducir costos de gas.
3. **Pruebas Exhaustivas**: Realizar pruebas exhaustivas en testnets antes de desplegar en mainnet.

### Despliegue en Mainnet

1. Asegurarse de tener suficiente ETH en la cuenta para cubrir los costos de despliegue
2. Desplegar el contrato en mainnet:
   ```bash
   truffle migrate --network mainnet
   ```

3. Verificar el contrato en [Etherscan](https://etherscan.io/):
   ```bash
   truffle run verify RentalContract --network mainnet
   ```

4. Guardar la dirección del contrato desplegado para usarla en la aplicación

## Integración con la Aplicación Flutter

### Configuración del Archivo .env

Añadir las siguientes variables al archivo .env de la aplicación Flutter:

```
BLOCKCHAIN_RPC_URL_LOCAL=http://127.0.0.1:7545
BLOCKCHAIN_RPC_URL_TESTNET=https://sepolia.infura.io/v3/your-infura-key
BLOCKCHAIN_RPC_URL_MAINNET=https://mainnet.infura.io/v3/your-infura-key
BLOCKCHAIN_CHAIN_ID_LOCAL=1337
BLOCKCHAIN_CHAIN_ID_TESTNET=11155111
BLOCKCHAIN_CHAIN_ID_MAINNET=1
BLOCKCHAIN_CONTRACT_ADDRESS_LOCAL=0x...
BLOCKCHAIN_CONTRACT_ADDRESS_TESTNET=0x...
BLOCKCHAIN_CONTRACT_ADDRESS_MAINNET=0x...
```

### Actualización del Servicio Blockchain

Modificar el archivo `lib/blockchain/blockchain_service.dart` para utilizar las variables de entorno:

```dart
// Actualizar el método initialize
Future<void> initialize({
  required String rpcUrl,
  required String privateKey,
  required int chainId,
  required String contractAddress,
}) async {
  _rpcUrl = rpcUrl;
  _chainId = chainId;

  // Initialize Ethereum client
  _client = Web3Client(_rpcUrl, Client());

  // Load contract ABI
  final contractABI = await rootBundle.loadString('assets/contracts/RentalContract.json');
  final contractAddr = EthereumAddress.fromHex(contractAddress);

  // Create credentials from private key
  _credentials = EthPrivateKey.fromHex(privateKey);

  // Load contract
  final contractData = jsonDecode(contractABI);
  _contract = DeployedContract(
    ContractAbi.fromJson(jsonEncode(contractData['abi']), 'RentalContract'),
    contractAddr,
  );

  // Get contract functions
  _createContract = _contract.function('createContract');
  _approveContract = _contract.function('approveContract');
  _makePayment = _contract.function('makePayment');
  _getContractDetails = _contract.function('getContractDetails');
}
```

### Actualización del Proveedor Blockchain

Modificar el archivo `lib/providers/blockchain_provider.dart` para añadir un método de selección de entorno:

```dart
// Añadir un método para seleccionar el entorno
Future<bool> initializeEnvironment(String environment) async {
  final dotenv = DotEnv();
  await dotenv.load();

  String rpcUrl;
  int chainId;
  String contractAddress;

  switch (environment) {
    case 'local':
      rpcUrl = dotenv.env['BLOCKCHAIN_RPC_URL_LOCAL'] ?? 'http://127.0.0.1:7545';
      chainId = int.parse(dotenv.env['BLOCKCHAIN_CHAIN_ID_LOCAL'] ?? '1337');
      contractAddress = dotenv.env['BLOCKCHAIN_CONTRACT_ADDRESS_LOCAL'] ?? '';
      break;
    case 'testnet':
      rpcUrl = dotenv.env['BLOCKCHAIN_RPC_URL_TESTNET'] ?? '';
      chainId = int.parse(dotenv.env['BLOCKCHAIN_CHAIN_ID_TESTNET'] ?? '11155111');
      contractAddress = dotenv.env['BLOCKCHAIN_CONTRACT_ADDRESS_TESTNET'] ?? '';
      break;
    case 'mainnet':
      rpcUrl = dotenv.env['BLOCKCHAIN_RPC_URL_MAINNET'] ?? '';
      chainId = int.parse(dotenv.env['BLOCKCHAIN_CHAIN_ID_MAINNET'] ?? '1');
      contractAddress = dotenv.env['BLOCKCHAIN_CONTRACT_ADDRESS_MAINNET'] ?? '';
      break;
    default:
      _message = 'Entorno no válido';
      notifyListeners();
      return false;
  }

  // Obtener la clave privada del almacenamiento seguro
  final privateKey = await _getPrivateKey();

  return initialize(
    rpcUrl: rpcUrl,
    privateKey: privateKey,
    chainId: chainId,
    contractAddress: contractAddress,
  );
}

// Método para obtener la clave privada de forma segura
Future<String> _getPrivateKey() async {
  // Implementar lógica para obtener la clave privada del almacenamiento seguro
  // Por ejemplo, usando flutter_secure_storage
  // En desarrollo, se puede usar una clave de prueba
  return '0x0000000000000000000000000000000000000000000000000000000000000000';
}
```

### Actualización del Archivo main.dart

Modificar el método `initializeBlockchain` en `lib/main.dart`:

```dart
// Initialize blockchain service with environment selection
Future<void> initializeBlockchain(BuildContext context, String environment) async {
  // Get the blockchain provider
  final blockchainProvider = Provider.of<BlockchainProvider>(context, listen: false);

  // Initialize with selected environment
  final success = await blockchainProvider.initializeEnvironment(environment);

  if (success) {
    print('Blockchain initialized successfully in $environment environment');
  } else {
    print('Failed to initialize blockchain in $environment environment');
  }
}
```

### Implementación de la Pantalla de Configuración Blockchain

Crear una nueva pantalla para configurar la conexión blockchain:

```dart
// lib/vista/settings/blockchain_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/blockchain_provider.dart';

class BlockchainSettingsScreen extends StatefulWidget {
  const BlockchainSettingsScreen({Key? key}) : super(key: key);

  @override
  State<BlockchainSettingsScreen> createState() => _BlockchainSettingsScreenState();
}

class _BlockchainSettingsScreenState extends State<BlockchainSettingsScreen> {
  String _selectedEnvironment = 'local';
  bool _isInitializing = false;

  @override
  Widget build(BuildContext context) {
    final blockchainProvider = Provider.of<BlockchainProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración Blockchain'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona el entorno de blockchain:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            RadioListTile<String>(
              title: const Text('Local (Ganache)'),
              subtitle: const Text('Para desarrollo y pruebas locales'),
              value: 'local',
              groupValue: _selectedEnvironment,
              onChanged: (value) {
                setState(() {
                  _selectedEnvironment = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Testnet (Sepolia)'),
              subtitle: const Text('Para pruebas en red de prueba'),
              value: 'testnet',
              groupValue: _selectedEnvironment,
              onChanged: (value) {
                setState(() {
                  _selectedEnvironment = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Mainnet (Ethereum)'),
              subtitle: const Text('Para producción'),
              value: 'mainnet',
              groupValue: _selectedEnvironment,
              onChanged: (value) {
                setState(() {
                  _selectedEnvironment = value!;
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isInitializing
                    ? null
                    : () async {
                        setState(() {
                          _isInitializing = true;
                        });

                        final success = await blockchainProvider.initializeEnvironment(_selectedEnvironment);

                        setState(() {
                          _isInitializing = false;
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Blockchain inicializado correctamente en entorno $_selectedEnvironment'
                                    : 'Error al inicializar blockchain: ${blockchainProvider.message}',
                              ),
                              backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      },
                child: _isInitializing
                    ? const CircularProgressIndicator()
                    : const Text('Conectar a Blockchain'),
              ),
            ),
            const SizedBox(height: 16),
            if (blockchainProvider.isInitialized) ...[
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Estado: Conectado a ${_selectedEnvironment}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Dirección del contrato: ${blockchainProvider.contractAddress}'),
            ],
          ],
        ),
      ),
    );
  }
}
```

## Pruebas y Verificación

### Pruebas Unitarias para Contratos Inteligentes

1. Crear archivos de prueba en la carpeta test:
   ```javascript
   // test/rental_contract_test.js
   const RentalContract = artifacts.require("RentalContract");

   contract("RentalContract", accounts => {
     const landlord = accounts[0];
     const tenant = accounts[1];
     let rentalContract;

     beforeEach(async () => {
       rentalContract = await RentalContract.new();
     });

     it("should create a new rental contract", async () => {
       const contractId = 1;
       const propertyId = 123;
       const rentAmount = web3.utils.toWei("0.1", "ether");
       const depositAmount = web3.utils.toWei("0.2", "ether");
       const startDate = Math.floor(Date.now() / 1000);
       const endDate = startDate + 30 * 24 * 60 * 60; // 30 days later
       const termsHash = "ipfs://QmHash";

       await rentalContract.createContract(
         contractId,
         landlord,
         tenant,
         propertyId,
         rentAmount,
         depositAmount,
         startDate,
         endDate,
         termsHash
       );

       const details = await rentalContract.getContractDetails(contractId);
       assert.equal(details.landlord, landlord);
       assert.equal(details.tenant, tenant);
       assert.equal(details.propertyId, propertyId);
       assert.equal(details.rentAmount, rentAmount);
       assert.equal(details.depositAmount, depositAmount);
       assert.equal(details.startDate, startDate);
       assert.equal(details.endDate, endDate);
       assert.equal(details.termsHash, termsHash);
     });

     // Añadir más pruebas para otras funciones
   });
   ```

2. Ejecutar las pruebas:
   ```bash
   truffle test
   ```

### Pruebas de Integración en la Aplicación Flutter

1. Crear pruebas de integración para la funcionalidad blockchain:
   ```dart
   // test/blockchain_integration_test.dart
   import 'package:flutter_test/flutter_test.dart';
   import 'package:rentals/blockchain/blockchain_service.dart';

   void main() {
     late BlockchainService blockchainService;

     setUp(() {
       blockchainService = BlockchainService();
     });

     test('Initialize blockchain service', () async {
       // Arrange
       const rpcUrl = 'http://127.0.0.1:7545';
       const privateKey = '0x...'; // Usar una clave privada de prueba
       const chainId = 1337;
       const contractAddress = '0x...'; // Usar la dirección del contrato desplegado en Ganache

       // Act
       await blockchainService.initialize(
         rpcUrl: rpcUrl,
         privateKey: privateKey,
         chainId: chainId,
         contractAddress: contractAddress,
       );

       // Assert
       expect(blockchainService.isInitialized, true);
     });
   }
   ```
   ```

## Consideraciones de Seguridad

### Gestión de Claves Privadas

1. **Nunca almacenar claves privadas en código fuente o archivos de configuración**
2. **Usar almacenamiento seguro para claves privadas**:
   ```dart
   import 'package:flutter_secure_storage/flutter_secure_storage.dart';

   class SecureStorage {
     final _storage = FlutterSecureStorage();

     Future<void> storePrivateKey(String privateKey) async {
       await _storage.write(key: 'ethereum_private_key', value: privateKey);
     }

     Future<String?> getPrivateKey() async {
       return await _storage.read(key: 'ethereum_private_key');
     }
   }
   ```

3. **Considerar soluciones de gestión de identidad descentralizada (DID)**

### Protección contra Ataques

1. **Validación de Entrada**: Validar todas las entradas antes de enviarlas a la blockchain
2. **Límites de Gas**: Establecer límites de gas adecuados para evitar ataques de denegación de servicio
3. **Protección contra Reentrancy**: Asegurarse de que el contrato inteligente esté protegido contra ataques de reentrancy

### Auditoría y Monitoreo

1. **Auditoría de Contratos**: Realizar auditorías de seguridad de los contratos inteligentes
2. **Monitoreo de Transacciones**: Implementar monitoreo de transacciones para detectar actividades sospechosas
3. **Actualizaciones de Seguridad**: Mantener actualizadas las dependencias y bibliotecas relacionadas con blockchain

## Optimización de Costos

### Reducción de Costos de Gas

1. **Optimización de Contratos**: Optimizar el código del contrato para reducir el consumo de gas
2. **Batch Transactions**: Agrupar múltiples transacciones en una sola cuando sea posible
3. **Uso de Sidechains o Layer 2**: Considerar el uso de soluciones de escalado como Polygon, Arbitrum o Optimism

### Estrategias de Implementación

1. **Implementación Gradual**: Comenzar con funcionalidades básicas y añadir más características con el tiempo
2. **Modelo Híbrido**: Usar blockchain solo para operaciones críticas y mantener otras operaciones fuera de la cadena
3. **Almacenamiento Descentralizado**: Usar IPFS para almacenar documentos y metadatos, guardando solo hashes en la blockchain

## Recursos Adicionales

### Documentación

- [Solidity Documentation](https://docs.soliditylang.org/)
- [Truffle Documentation](https://trufflesuite.com/docs/truffle/)
- [Web3.js Documentation](https://web3js.readthedocs.io/)
- [Ethereum Development Documentation](https://ethereum.org/developers/)

### Herramientas

- [Remix IDE](https://remix.ethereum.org/) - IDE en línea para desarrollo de contratos inteligentes
- [Hardhat](https://hardhat.org/) - Entorno de desarrollo para Ethereum
- [OpenZeppelin](https://openzeppelin.com/) - Biblioteca de contratos inteligentes seguros y auditados
- [Infura](https://infura.io/) - Infraestructura para acceder a redes Ethereum

### Comunidad

- [Ethereum StackExchange](https://ethereum.stackexchange.com/)
- [r/ethdev](https://www.reddit.com/r/ethdev/)
- [Ethereum Magicians](https://ethereum-magicians.org/)
