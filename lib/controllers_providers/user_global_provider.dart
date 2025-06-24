import 'package:flutter/material.dart';
import '../models/user_model.dart';

/// A singleton provider that holds the global user state
/// This provider can be accessed from anywhere in the app
class UserGlobalProvider extends ChangeNotifier {
  static final UserGlobalProvider _instance = UserGlobalProvider._internal();
  
  // Private constructor
  UserGlobalProvider._internal();
  
  // Factory constructor to return the same instance
  factory UserGlobalProvider() {
    return _instance;
  }
  
  // The current authenticated user
  UserModel? _currentUser;
  
  // Getter for the current user
  UserModel? get currentUser => _currentUser;
  
  // Setter for the current user
  set currentUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }
  
  // Method to update the current user
  void updateUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }
  
  // Method to clear the current user (logout)
  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
  
  // Check if user is authenticated
  bool get isAuthenticated => _currentUser != null;
  
  // Check if user is a property owner
  bool get isPropietario => _currentUser?.tipoUsuario == 'propietario';
  
  // Check if user is a client
  bool get isCliente => _currentUser?.tipoUsuario == 'cliente';
}