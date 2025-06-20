import 'package:cloud_firestore/cloud_firestore.dart';

class ContractModel {
  final String id;
  final String propertyId;
  final String ownerId;
  final String renterId;
  final DateTime startDate;
  final DateTime endDate;
  final double monthlyRent;
  final double securityDeposit;
  final String status; // draft, pending, active, completed, terminated
  final String? blockchainTxHash; // Blockchain transaction hash
  final String? blockchainContractAddress; // Smart contract address on blockchain
  final Map<String, dynamic>? additionalTerms;
  final bool isOwnerSigned;
  final bool isRenterSigned;
  final DateTime createdAt;
  final DateTime? lastUpdated;

  ContractModel({
    required this.id,
    required this.propertyId,
    required this.ownerId,
    required this.renterId,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.securityDeposit,
    required this.status,
    this.blockchainTxHash,
    this.blockchainContractAddress,
    this.additionalTerms,
    required this.isOwnerSigned,
    required this.isRenterSigned,
    required this.createdAt,
    this.lastUpdated,
  });

  // Create a ContractModel from a Firebase document
  factory ContractModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ContractModel(
      id: doc.id,
      propertyId: data['propertyId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      renterId: data['renterId'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      monthlyRent: (data['monthlyRent'] ?? 0).toDouble(),
      securityDeposit: (data['securityDeposit'] ?? 0).toDouble(),
      status: data['status'] ?? 'draft',
      blockchainTxHash: data['blockchainTxHash'],
      blockchainContractAddress: data['blockchainContractAddress'],
      additionalTerms: data['additionalTerms'],
      isOwnerSigned: data['isOwnerSigned'] ?? false,
      isRenterSigned: data['isRenterSigned'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastUpdated: data['lastUpdated'] != null 
          ? (data['lastUpdated'] as Timestamp).toDate() 
          : null,
    );
  }

  // Convert ContractModel to a map for Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'ownerId': ownerId,
      'renterId': renterId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'monthlyRent': monthlyRent,
      'securityDeposit': securityDeposit,
      'status': status,
      'blockchainTxHash': blockchainTxHash,
      'blockchainContractAddress': blockchainContractAddress,
      'additionalTerms': additionalTerms,
      'isOwnerSigned': isOwnerSigned,
      'isRenterSigned': isRenterSigned,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    };
  }

  // Create a copy of the ContractModel with updated fields
  ContractModel copyWith({
    String? id,
    String? propertyId,
    String? ownerId,
    String? renterId,
    DateTime? startDate,
    DateTime? endDate,
    double? monthlyRent,
    double? securityDeposit,
    String? status,
    String? blockchainTxHash,
    String? blockchainContractAddress,
    Map<String, dynamic>? additionalTerms,
    bool? isOwnerSigned,
    bool? isRenterSigned,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return ContractModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      ownerId: ownerId ?? this.ownerId,
      renterId: renterId ?? this.renterId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      status: status ?? this.status,
      blockchainTxHash: blockchainTxHash ?? this.blockchainTxHash,
      blockchainContractAddress: blockchainContractAddress ?? this.blockchainContractAddress,
      additionalTerms: additionalTerms ?? this.additionalTerms,
      isOwnerSigned: isOwnerSigned ?? this.isOwnerSigned,
      isRenterSigned: isRenterSigned ?? this.isRenterSigned,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}