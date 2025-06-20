import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String propertyId;
  final String ownerId;
  final String renterId;
  final DateTime appointmentDateTime;
  final String status; // pending, confirmed, cancelled, completed
  final String? notes;
  final DateTime createdAt;
  final DateTime? lastUpdated;

  AppointmentModel({
    required this.id,
    required this.propertyId,
    required this.ownerId,
    required this.renterId,
    required this.appointmentDateTime,
    required this.status,
    this.notes,
    required this.createdAt,
    this.lastUpdated,
  });

  // Create an AppointmentModel from a Firebase document
  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      propertyId: data['propertyId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      renterId: data['renterId'] ?? '',
      appointmentDateTime: (data['appointmentDateTime'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastUpdated: data['lastUpdated'] != null 
          ? (data['lastUpdated'] as Timestamp).toDate() 
          : null,
    );
  }

  // Convert AppointmentModel to a map for Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'ownerId': ownerId,
      'renterId': renterId,
      'appointmentDateTime': Timestamp.fromDate(appointmentDateTime),
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    };
  }

  // Create a copy of the AppointmentModel with updated fields
  AppointmentModel copyWith({
    String? id,
    String? propertyId,
    String? ownerId,
    String? renterId,
    DateTime? appointmentDateTime,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      ownerId: ownerId ?? this.ownerId,
      renterId: renterId ?? this.renterId,
      appointmentDateTime: appointmentDateTime ?? this.appointmentDateTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}