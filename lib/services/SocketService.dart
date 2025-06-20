import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';

class SocketService with ChangeNotifier {
  IO.Socket? _socket;
  bool _isConnected = false;
  
  // Getters
  bool get isConnected => _isConnected;
  IO.Socket? get socket => _socket;
  
  // Initialize socket connection
  void initSocket(String serverUrl) {
    try {
      _socket = IO.io(serverUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });
      
      _socket!.onConnect((_) {
        print('Socket connected to $serverUrl');
        _isConnected = true;
        notifyListeners();
      });
      
      _socket!.onDisconnect((_) {
        print('Socket disconnected');
        _isConnected = false;
        notifyListeners();
      });
      
      _socket!.onError((error) {
        print('Socket error: $error');
        _isConnected = false;
        notifyListeners();
      });
      
      // Listen for authorization responses
      _socket!.on('authorization_response', (data) {
        print('Authorization response received: $data');
        // Handle authorization response
        // This could update the UI or trigger a notification
      });
      
    } catch (e) {
      print('Error initializing socket: $e');
      _isConnected = false;
      notifyListeners();
    }
  }
  
  // Send authorization update
  void sendAuthorizationUpdate(String ingresoId, String status, String guardiaId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('authorization_update', {
        'ingresoId': ingresoId,
        'status': status,
        'guardiaId': guardiaId,
      });
      print('Authorization update sent for entry: $ingresoId');
    } else {
      print('Socket not connected. Cannot send authorization update.');
    }
  }
  
  // Disconnect socket
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      notifyListeners();
    }
  }
}