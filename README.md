# Rental Properties Application

A Flutter application for renting houses or hotel rooms with blockchain-based contracts.

## Overview

This application allows property owners to list their properties for rent, and renters to browse and request appointments to view properties. The rental contracts are secured using blockchain technology for transparency and security.

## Features

### For Property Owners
- Create and manage property listings
- View and respond to appointment requests
- Create and manage rental contracts
- Track property statistics

### For Renters
- Browse available properties
- Filter and search for properties
- Request appointments to view properties
- Sign rental contracts
- Save favorite properties

### Blockchain Integration
The application uses Ethereum blockchain technology to secure rental contracts, providing:
- Immutable contract records
- Transparent terms and conditions
- Secure digital signatures
- Verifiable transaction history

## Technical Implementation

### Architecture
The application follows a clean architecture approach with:
- **Models**: Data structures for users, properties, appointments, and contracts
- **Services**: Authentication, database, and blockchain services
- **Screens**: UI components organized by feature

### Technologies Used
- **Flutter**: Cross-platform UI framework
- **Firebase**: Authentication, database, and storage
- **Provider**: State management
- **Web3dart**: Ethereum blockchain integration

## Blockchain Implementation

### Smart Contract
The application includes a simplified rental contract smart contract with the following functions:
- `createRentalContract`: Create a new rental contract on the blockchain
- `signContractAsOwner`: Sign the contract as the property owner
- `signContractAsRenter`: Sign the contract as the renter
- `terminateContract`: Terminate an active contract
- `getContractDetails`: Retrieve contract details from the blockchain

### Integration
The blockchain integration is handled by the `BlockchainService` class, which:
- Initializes the Web3 client
- Manages Ethereum credentials
- Interacts with the smart contract
- Converts between application models and blockchain data

## Getting Started

### Prerequisites
- Flutter SDK
- Firebase account
- Ethereum wallet (for testing blockchain features)

### Setup
1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase:
   - Create a new Firebase project
   - Add your app to the Firebase project
   - Download and add the configuration files
4. Configure Ethereum:
   - Create an Infura account for Ethereum API access
   - Update the RPC URL in `blockchain_service.dart`
5. Run the application with `flutter run`

## Future Development

### Property Management
- Implement property creation and editing screens
- Add image upload functionality
- Implement property search and filtering

### Appointment System
- Create appointment request and management screens
- Implement notifications for appointment status changes
- Add calendar integration

### Contract Management
- Develop full contract creation and management screens
- Implement digital signature verification
- Add payment integration

### Blockchain Enhancements
- Deploy a production-ready smart contract
- Implement multi-signature functionality
- Add escrow for security deposits
- Integrate with a stablecoin for rent payments

## Blockchain Development Guide

For developers continuing the blockchain integration:

1. **Smart Contract Development**:
   - Use Solidity for Ethereum smart contract development
   - Consider using frameworks like Truffle or Hardhat
   - Implement proper access control and security measures
   - Test thoroughly on testnets before deploying to mainnet

2. **Contract Deployment**:
   - Deploy to Ethereum testnets (Goerli, Sepolia) for testing
   - Use gas optimization techniques to reduce transaction costs
   - Consider layer 2 solutions for lower fees and faster transactions

3. **Integration with Flutter**:
   - Use web3dart for Ethereum interactions
   - Implement proper error handling for blockchain operations
   - Consider caching blockchain data for better performance
   - Provide fallback mechanisms for when blockchain operations fail

4. **Security Considerations**:
   - Never store private keys in code or version control
   - Use secure storage for credentials
   - Implement proper validation for all blockchain transactions
   - Consider using hardware wallets for enhanced security

## License
This project is licensed under the MIT License.
