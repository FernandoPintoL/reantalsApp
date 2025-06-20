/*
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/property_model.dart';
import '../models/appointment_model.dart';
import '../models/contract_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference _propertiesCollection = FirebaseFirestore.instance.collection('properties');
  final CollectionReference _appointmentsCollection = FirebaseFirestore.instance.collection('appointments');
  final CollectionReference _contractsCollection = FirebaseFirestore.instance.collection('contracts');

  // User methods
  Future<UserModel?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Future<void> updateUserFavorites(String userId, List<String> favoriteProperties) async {
    try {
      await _usersCollection.doc(userId).update({
        'favoriteProperties': favoriteProperties,
      });
    } catch (e) {
      print('Error updating user favorites: $e');
      throw e;
    }
  }

  // Property methods
  Future<String> createProperty(PropertyModel property) async {
    try {
      DocumentReference docRef = await _propertiesCollection.add(property.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating property: $e');
      throw e;
    }
  }

  Future<PropertyModel?> getProperty(String propertyId) async {
    try {
      DocumentSnapshot doc = await _propertiesCollection.doc(propertyId).get();
      if (doc.exists) {
        return PropertyModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting property: $e');
      return null;
    }
  }

  Future<List<PropertyModel>> getProperties({
    String? ownerId,
    bool? isAvailable,
    int? limit,
    String? propertyType,
    double? maxPrice,
    int? minBedrooms,
  }) async {
    try {
      Query query = _propertiesCollection;
      
      if (ownerId != null) {
        query = query.where('ownerId', isEqualTo: ownerId);
      }
      
      if (isAvailable != null) {
        query = query.where('isAvailable', isEqualTo: isAvailable);
      }
      
      if (propertyType != null) {
        query = query.where('propertyType', isEqualTo: propertyType);
      }
      
      if (maxPrice != null) {
        query = query.where('price', isLessThanOrEqualTo: maxPrice);
      }
      
      if (minBedrooms != null) {
        query = query.where('bedrooms', isGreaterThanOrEqualTo: minBedrooms);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      QuerySnapshot snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => PropertyModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting properties: $e');
      return [];
    }
  }

  Future<void> updateProperty(String propertyId, PropertyModel property) async {
    try {
      await _propertiesCollection.doc(propertyId).update(property.toFirestore());
    } catch (e) {
      print('Error updating property: $e');
      throw e;
    }
  }

  Future<void> deleteProperty(String propertyId) async {
    try {
      await _propertiesCollection.doc(propertyId).delete();
    } catch (e) {
      print('Error deleting property: $e');
      throw e;
    }
  }

  // Appointment methods
  Future<String> createAppointment(AppointmentModel appointment) async {
    try {
      DocumentReference docRef = await _appointmentsCollection.add(appointment.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating appointment: $e');
      throw e;
    }
  }

  Future<AppointmentModel?> getAppointment(String appointmentId) async {
    try {
      DocumentSnapshot doc = await _appointmentsCollection.doc(appointmentId).get();
      if (doc.exists) {
        return AppointmentModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting appointment: $e');
      return null;
    }
  }

  Future<List<AppointmentModel>> getAppointments({
    String? propertyId,
    String? ownerId,
    String? renterId,
    String? status,
  }) async {
    try {
      Query query = _appointmentsCollection;
      
      if (propertyId != null) {
        query = query.where('propertyId', isEqualTo: propertyId);
      }
      
      if (ownerId != null) {
        query = query.where('ownerId', isEqualTo: ownerId);
      }
      
      if (renterId != null) {
        query = query.where('renterId', isEqualTo: renterId);
      }
      
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      
      QuerySnapshot snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting appointments: $e');
      return [];
    }
  }

  Future<void> updateAppointment(String appointmentId, AppointmentModel appointment) async {
    try {
      await _appointmentsCollection.doc(appointmentId).update(appointment.toFirestore());
    } catch (e) {
      print('Error updating appointment: $e');
      throw e;
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _appointmentsCollection.doc(appointmentId).delete();
    } catch (e) {
      print('Error deleting appointment: $e');
      throw e;
    }
  }

  // Contract methods
  Future<String> createContract(ContractModel contract) async {
    try {
      DocumentReference docRef = await _contractsCollection.add(contract.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating contract: $e');
      throw e;
    }
  }

  Future<ContractModel?> getContract(String contractId) async {
    try {
      DocumentSnapshot doc = await _contractsCollection.doc(contractId).get();
      if (doc.exists) {
        return ContractModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting contract: $e');
      return null;
    }
  }

  Future<List<ContractModel>> getContracts({
    String? propertyId,
    String? ownerId,
    String? renterId,
    String? status,
  }) async {
    try {
      Query query = _contractsCollection;
      
      if (propertyId != null) {
        query = query.where('propertyId', isEqualTo: propertyId);
      }
      
      if (ownerId != null) {
        query = query.where('ownerId', isEqualTo: ownerId);
      }
      
      if (renterId != null) {
        query = query.where('renterId', isEqualTo: renterId);
      }
      
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      
      QuerySnapshot snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => ContractModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting contracts: $e');
      return [];
    }
  }

  Future<void> updateContract(String contractId, ContractModel contract) async {
    try {
      await _contractsCollection.doc(contractId).update(contract.toFirestore());
    } catch (e) {
      print('Error updating contract: $e');
      throw e;
    }
  }

  Future<void> deleteContract(String contractId) async {
    try {
      await _contractsCollection.doc(contractId).delete();
    } catch (e) {
      print('Error deleting contract: $e');
      throw e;
    }
  }
}*/
