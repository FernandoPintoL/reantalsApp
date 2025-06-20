/*
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email and password
  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required bool isOwner,
    String? phoneNumber,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;
      
      if (user != null) {
        // Create user document in Firestore
        UserModel newUser = UserModel(
          id: user.uid,
          email: email,
          name: name,
          phoneNumber: phoneNumber,
          profileImageUrl: null,
          isOwner: isOwner,
          favoriteProperties: [],
          createdAt: DateTime.now(),
        );
        
        await _firestore.collection('users').doc(user.uid).set(newUser.toFirestore());
        
        // Update display name in Firebase Auth
        await user.updateDisplayName(name);
        
        return newUser;
      }
      return null;
    } catch (e) {
      print('Error registering user: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;
      
      if (user != null) {
        // Get user data from Firestore
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      throw e;
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile() async {
    try {
      User? user = _auth.currentUser;
      
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<UserModel?> updateUserProfile({
    required String name,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      User? user = _auth.currentUser;
      
      if (user != null) {
        // Get current user data
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        UserModel currentUser = UserModel.fromFirestore(doc);
        
        // Create updated user
        UserModel updatedUser = currentUser.copyWith(
          name: name,
          phoneNumber: phoneNumber,
          profileImageUrl: profileImageUrl,
          lastUpdated: DateTime.now(),
        );
        
        // Update in Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'name': name,
          'phoneNumber': phoneNumber,
          'profileImageUrl': profileImageUrl,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        
        // Update display name in Firebase Auth
        await user.updateDisplayName(name);
        
        return updatedUser;
      }
      return null;
    } catch (e) {
      print('Error updating user profile: $e');
      return null;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error resetting password: $e');
      throw e;
    }
  }
}*/
