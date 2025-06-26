import 'dart:async';
import 'package:flutter/material.dart';
import 'socket_service.dart';

class WebSocketAdminService {
  final SocketService _socketService;

  // Stream controller for admin events
  final _adminEventsController = StreamController<Map<String, dynamic>>.broadcast();

  // Streams that can be listened to from anywhere in the app
  Stream<Map<String, dynamic>> get adminEvents => _adminEventsController.stream;
  Stream<SocketConnectionStatus> get connectionStatus => _socketService.connectionStatus;
  Stream<int> get latency => _socketService.latency;

  // Constructor
  WebSocketAdminService(this._socketService) {
    // Listen to connection status changes
    _socketService.connectionStatus.listen((status) {
      _adminEventsController.add({
        'type': 'connection_status_changed',
        'status': status.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  // Get current connection status
  SocketConnectionStatus getConnectionStatus() {
    return _socketService.getConnectionStatus();
  }

  // Get connection statistics
  Map<String, dynamic> getConnectionStats() {
    return _socketService.getConnectionStats();
  }

  // Connect to the socket server
  void connect() {
    _socketService.initialize();
    _logAdminEvent('connect_requested');
  }

  // Disconnect from the socket server
  void disconnect() {
    _socketService.disconnect();
    _logAdminEvent('disconnect_requested');
  }

  // Reconnect to the socket server
  void reconnect() {
    _socketService.reconnect();
    _logAdminEvent('reconnect_requested');
  }

  // Configure auto-reconnect settings
  void configureReconnect({
    bool? autoReconnect,
    int? maxAttempts,
    Duration? interval, // For backward compatibility
  }) {
    _socketService.configureReconnect(
      autoReconnect: autoReconnect,
      maxAttempts: maxAttempts,
      baseInterval: interval, // Map to new parameter name
    );
    _logAdminEvent('reconnect_configured', {
      'autoReconnect': autoReconnect,
      'maxAttempts': maxAttempts,
      'interval': interval?.inSeconds,
    });
  }

  // Configure heartbeat settings
  void setHeartbeatSettings({
    Duration? interval,
    int? maxMissed,
  }) {
    _socketService.configureHeartbeat(
      interval: interval,
      maxMissed: maxMissed,
    );
    _logAdminEvent('heartbeat_configured', {
      'interval': interval?.inSeconds,
      'maxMissed': maxMissed,
    });
  }

  // Test connection by sending a ping
  void testConnection() {
    _socketService.testConnection();
    _logAdminEvent('connection_test_requested');
  }

  // Clear connection statistics
  void clearConnectionStats() {
    _socketService.clearConnectionStats();
    _logAdminEvent('connection_stats_cleared');
  }

  // Get connection quality rating (0-100)
  int getConnectionQuality() {
    final quality = _socketService.getConnectionQuality();
    _logAdminEvent('connection_quality_checked', {'quality': quality});
    return quality;
  }

  // Get average latency
  int getAverageLatency() {
    return _socketService.getAverageLatency();
  }

  // Join a room for a specific user
  void joinUserRoom(int userId) {
    _socketService.joinUserRoom(userId);
    _logAdminEvent('join_user_room', {'userId': userId});
  }

  // Leave a room for a specific user
  void leaveUserRoom(int userId) {
    _socketService.leaveUserRoom(userId);
    _logAdminEvent('leave_user_room', {'userId': userId});
  }

  // Join a room for a specific property
  void joinPropertyRoom(int inmuebleId) {
    _socketService.joinPropertyRoom(inmuebleId);
    _logAdminEvent('join_property_room', {'inmuebleId': inmuebleId});
  }

  // Leave a room for a specific property
  void leavePropertyRoom(int inmuebleId) {
    _socketService.leavePropertyRoom(inmuebleId);
    _logAdminEvent('leave_property_room', {'inmuebleId': inmuebleId});
  }

  // Log admin event
  void _logAdminEvent(String eventType, [Map<String, dynamic>? data]) {
    final event = <String, dynamic>{
      'type': eventType,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (data != null) {
      event.addAll(data);
    }

    _adminEventsController.add(event);
    debugPrint('WebSocket Admin Event: $event');
  }

  // Dispose resources
  void dispose() {
    _adminEventsController.close();
  }
}
