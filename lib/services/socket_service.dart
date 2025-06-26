import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'notification_service.dart';
import 'UrlConfigProvider.dart';

enum SocketConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error
}

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket _socket;
  bool _isConnected = false;
  final NotificationService _notificationService = NotificationService();
  final UrlConfigProvider _urlConfigProvider = UrlConfigProvider();

  // Connection status
  SocketConnectionStatus _connectionStatus = SocketConnectionStatus.disconnected;
  final _connectionStatusController = StreamController<SocketConnectionStatus>.broadcast();

  // Reconnection settings
  bool _autoReconnect = true;
  int _reconnectAttempts = 0;
  int _maxReconnectAttempts = 10;
  Duration _baseReconnectInterval = const Duration(seconds: 2);
  Duration _maxReconnectInterval = const Duration(minutes: 2);
  Timer? _reconnectTimer;

  // Heartbeat settings
  Timer? _heartbeatTimer;
  Duration _heartbeatInterval = const Duration(seconds: 30);
  int _missedHeartbeats = 0;
  int _maxMissedHeartbeats = 2;

  // Connection quality monitoring
  int _latencyMs = 0;
  List<int> _latencyHistory = [];
  int _maxLatencyHistorySize = 10;
  DateTime? _lastPingSent;
  final _latencyController = StreamController<int>.broadcast();

  // Connection statistics
  DateTime? _connectedSince;
  int _totalReconnects = 0;
  int _totalMessages = 0;
  int _totalPings = 0;
  int _totalPongs = 0;
  String _lastError = '';
  bool _wasConnected = false; // Track if we were ever connected

  // Stream controllers for different events
  final _contractGeneratedController = StreamController<Map<String, dynamic>>.broadcast();
  final _paymentReceivedController = StreamController<Map<String, dynamic>>.broadcast();
  final _requestStatusChangedController = StreamController<Map<String, dynamic>>.broadcast();

  // Streams that can be listened to from anywhere in the app
  Stream<Map<String, dynamic>> get onContractGenerated => _contractGeneratedController.stream;
  Stream<Map<String, dynamic>> get onPaymentReceived => _paymentReceivedController.stream;
  Stream<Map<String, dynamic>> get onRequestStatusChanged => _requestStatusChangedController.stream;
  Stream<SocketConnectionStatus> get connectionStatus => _connectionStatusController.stream;
  Stream<int> get latency => _latencyController.stream;

  // Private constructor
  SocketService._internal();

  // Factory constructor to return the same instance
  factory SocketService() {
    return _instance;
  }

  // Initialize and connect to the socket server
  void initialize() {
    if (_isConnected) return;

    _updateConnectionStatus(SocketConnectionStatus.connecting);
    final socketUrl = _urlConfigProvider.currentBaseUrlSocket;
    debugPrint('Connecting to socket server at: $socketUrl');

    try {
      // Optimize socket options for better performance and reliability
      _socket = IO.io(socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnection': false, // We'll handle reconnection manually
        'timeout': 15000, // 15 seconds timeout
        'forceNew': true, // Force a new connection
        'upgrade': true, // Allow transport upgrade
        'rejectUnauthorized': false, // Accept self-signed certificates
        'extraHeaders': {'X-Client-Version': '1.0.0'}, // Add custom headers
      });

      _socket.onConnect((_) {
        debugPrint('Socket connected successfully');
        _isConnected = true;
        _connectedSince = DateTime.now();
        _reconnectAttempts = 0;
        _cancelReconnectTimer();
        _updateConnectionStatus(SocketConnectionStatus.connected);
        _wasConnected = true;

        // Start heartbeat timer to detect silent disconnections
        _startHeartbeat();

        // Send an initial ping to measure latency
        _sendPing();
      });

      _socket.onDisconnect((_) {
        debugPrint('Socket disconnected');
        _isConnected = false;
        _updateConnectionStatus(SocketConnectionStatus.disconnected);

        // Stop heartbeat timer
        _stopHeartbeat();

        // Start reconnection process if auto-reconnect is enabled
        if (_autoReconnect) {
          _attemptReconnect();
        }
      });

      _socket.onError((error) {
        final errorMsg = error.toString();
        debugPrint('Socket error: $errorMsg');
        _lastError = 'Error: $errorMsg';
        _updateConnectionStatus(SocketConnectionStatus.error);

        // Log more detailed error information
        if (errorMsg.contains('timeout')) {
          debugPrint('Socket timeout error - check network connection');
        } else if (errorMsg.contains('refused')) {
          debugPrint('Connection refused - server may be down');
        } else if (errorMsg.contains('certificate')) {
          debugPrint('SSL certificate error - check server configuration');
        }

        // Disconnect on error to trigger reconnect
        if (_isConnected) {
          _socket.disconnect();
        }
      });

      _socket.onConnectError((error) {
        final errorMsg = error.toString();
        debugPrint('Socket connect error: $errorMsg');
        _lastError = 'Connect error: $errorMsg';
        _updateConnectionStatus(SocketConnectionStatus.error);

        // Log more detailed error information
        if (errorMsg.contains('timeout')) {
          debugPrint('Connection timeout - server may be slow or unreachable');
        } else if (errorMsg.contains('refused')) {
          debugPrint('Connection refused - server may be down or wrong port');
        } else if (errorMsg.contains('not found')) {
          debugPrint('Host not found - check URL configuration');
        }

        // Attempt reconnect on connection error
        if (_autoReconnect) {
          _attemptReconnect();
        }
      });

      _socket.onConnectTimeout((_) {
        debugPrint('Socket connect timeout after 15 seconds');
        _lastError = 'Connection timeout';
        _updateConnectionStatus(SocketConnectionStatus.error);

        // Attempt reconnect on timeout
        if (_autoReconnect) {
          _attemptReconnect();
        }
      });

      // Listen for ping responses to measure latency
      _socket.on('pong', (data) {
        if (_lastPingSent != null) {
          final now = DateTime.now();
          final latency = now.difference(_lastPingSent!).inMilliseconds;
          _latencyMs = latency;
          _totalPongs++;

          // Add to latency history for tracking connection quality
          _latencyHistory.add(latency);
          if (_latencyHistory.length > _maxLatencyHistorySize) {
            _latencyHistory.removeAt(0);
          }

          // Notify listeners of the new latency
          _latencyController.add(latency);

          debugPrint('Received pong: Latency ${latency}ms');
        }
      });

      // Listen for heartbeat responses
      _socket.on('heartbeat', (_) {
        debugPrint('Received heartbeat from server');
        _missedHeartbeats = 0;
      });

      // Listen for contract generation events
      _socket.on('contract-generated', (data) {
        debugPrint('Contract generated: $data');
        _totalMessages++;
        _contractGeneratedController.add(data);

        // Show notification
        if (data['propertyName'] != null && data['solicitudId'] != null) {
          _notificationService.showContractGeneratedNotification(
            solicitudId: data['solicitudId'],
            propertyName: data['propertyName'],
          );
        }
      });

      // Listen for payment events
      _socket.on('payment-received', (data) {
        debugPrint('Payment received: $data');
        _totalMessages++;
        _paymentReceivedController.add(data);

        // Show notification
        if (data['propertyName'] != null && data['contratoId'] != null && data['amount'] != null) {
          _notificationService.showPaymentReceivedNotification(
            contratoId: data['contratoId'],
            propertyName: data['propertyName'],
            amount: data['amount'].toDouble(),
          );
        }
      });

      // Listen for request status change events
      _socket.on('request-status-changed', (data) {
        debugPrint('Request status changed: $data');
        _totalMessages++;
        _requestStatusChangedController.add(data);

        // Show notification
        if (data['propertyName'] != null && data['solicitudId'] != null && data['status'] != null) {
          _notificationService.showRequestStatusChangedNotification(
            solicitudId: data['solicitudId'],
            propertyName: data['propertyName'],
            status: data['status'],
          );
        }
      });

    } catch (e) {
      debugPrint('Error initializing socket: $e');
      _lastError = e.toString();
      _updateConnectionStatus(SocketConnectionStatus.error);
    }
  }

  // Update connection status and notify listeners
  void _updateConnectionStatus(SocketConnectionStatus status) {
    _connectionStatus = status;
    _connectionStatusController.add(status);
  }

  // Start heartbeat timer to detect silent disconnections
  void _startHeartbeat() {
    _stopHeartbeat(); // Stop any existing heartbeat timer
    _missedHeartbeats = 0;

    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (!_isConnected) {
        _stopHeartbeat();
        return;
      }

      // Send heartbeat to server
      _socket.emit('heartbeat', {
        'timestamp': DateTime.now().toIso8601String(),
        'clientId': 'flutter-client',
      });

      _missedHeartbeats++;
      debugPrint('Sent heartbeat (missed: $_missedHeartbeats/$_maxMissedHeartbeats)');

      // If we've missed too many heartbeats, consider the connection dead
      if (_missedHeartbeats >= _maxMissedHeartbeats) {
        debugPrint('Too many missed heartbeats, reconnecting...');
        _stopHeartbeat();

        // Force disconnect and reconnect
        if (_isConnected) {
          _socket.disconnect();
          // The onDisconnect handler will trigger reconnection
        } else {
          _attemptReconnect();
        }
      }
    });
  }

  // Stop heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // Send ping to measure latency
  void _sendPing() {
    if (!_isConnected) return;

    _lastPingSent = DateTime.now();
    _totalPings++;

    _socket.emit('ping', {
      'timestamp': _lastPingSent!.toIso8601String(),
      'sequence': _totalPings,
    });

    debugPrint('Sent ping #$_totalPings');
  }

  // Calculate average latency from history
  int getAverageLatency() {
    if (_latencyHistory.isEmpty) return 0;

    final sum = _latencyHistory.reduce((a, b) => a + b);
    return sum ~/ _latencyHistory.length;
  }

  // Attempt to reconnect to the socket server with exponential backoff
  void _attemptReconnect() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) return;

    _reconnectAttempts++;
    _totalReconnects++;

    if (_reconnectAttempts > _maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached ((_maxReconnectAttempts))');
      _updateConnectionStatus(SocketConnectionStatus.error);
      return;
    }

    _updateConnectionStatus(SocketConnectionStatus.reconnecting);

    // Calculate delay with exponential backoff and jitter
    final baseDelay = _baseReconnectInterval.inMilliseconds;
    final maxDelay = _maxReconnectInterval.inMilliseconds;

    // Exponential backoff: delay = baseDelay * 2^(attempts-1)
    int delay = baseDelay * math.pow(2, _reconnectAttempts - 1).toInt();

    // Add jitter to prevent reconnection storms (±20%)
    final jitter = (delay * 0.2 * (math.Random().nextDouble() * 2 - 1)).toInt();
    delay = (delay + jitter).clamp(baseDelay, maxDelay);

    debugPrint('Attempting to reconnect (${_reconnectAttempts}/${_maxReconnectAttempts}) in ${delay}ms...');

    // Schedule reconnect attempt
    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      if (!_isConnected) {
        initialize();
      }
    });
  }

  // Cancel reconnect timer
  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // Join a room for a specific user
  void joinUserRoom(int userId) {
    if (!_isConnected) initialize();
    _socket.emit('join-user-room', userId);
    debugPrint('Joined user room: $userId');
  }

  // Leave a room for a specific user
  void leaveUserRoom(int userId) {
    if (!_isConnected) return;
    _socket.emit('leave-user-room', userId);
    debugPrint('Left user room: $userId');
  }

  // Join a room for a specific property
  void joinPropertyRoom(int inmuebleId) {
    if (!_isConnected) initialize();
    _socket.emit('join-property-room', inmuebleId);
    debugPrint('Joined property room: $inmuebleId');
  }

  // Leave a room for a specific property
  void leavePropertyRoom(int inmuebleId) {
    if (!_isConnected) return;
    _socket.emit('leave-property-room', inmuebleId);
    debugPrint('Left property room: $inmuebleId');
  }

  // Emit contract generated event
  void emitContractGenerated({
    required int solicitudId,
    required int contratoId,
    required String propertyName,
    required int clientId,
    required int propietarioId,
  }) {
    if (!_isConnected) initialize();
    _socket.emit('contract-generated', {
      'solicitudId': solicitudId,
      'contratoId': contratoId,
      'propertyName': propertyName,
      'clientId': clientId,
      'propietarioId': propietarioId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Emit payment received event
  void emitPaymentReceived({
    required int contratoId,
    required String propertyName,
    required double amount,
    required int clientId,
    required int propietarioId,
  }) {
    if (!_isConnected) initialize();
    _socket.emit('payment-received', {
      'contratoId': contratoId,
      'propertyName': propertyName,
      'amount': amount,
      'clientId': clientId,
      'propietarioId': propietarioId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Emit request status changed event
  void emitRequestStatusChanged({
    required int solicitudId,
    required String propertyName,
    required String status,
    required int clientId,
    required int propietarioId,
  }) {
    if (!_isConnected) initialize();
    _socket.emit('request-status-changed', {
      'solicitudId': solicitudId,
      'propertyName': propertyName,
      'status': status,
      'clientId': clientId,
      'propietarioId': propietarioId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Manually reconnect to the socket server
  void reconnect() {
    disconnect();
    _reconnectAttempts = 0;
    initialize();
  }

  // Configure auto-reconnect settings
  void configureReconnect({
    bool? autoReconnect,
    int? maxAttempts,
    Duration? baseInterval,
    Duration? maxInterval,
  }) {
    if (autoReconnect != null) _autoReconnect = autoReconnect;
    if (maxAttempts != null) _maxReconnectAttempts = maxAttempts;
    if (baseInterval != null) _baseReconnectInterval = baseInterval;
    if (maxInterval != null) _maxReconnectInterval = maxInterval;

    debugPrint('Reconnect settings updated: autoReconnect=$_autoReconnect, maxAttempts=$_maxReconnectAttempts, '
        'baseInterval=${_baseReconnectInterval.inSeconds}s, maxInterval=${_maxReconnectInterval.inSeconds}s');
  }

  // Configure heartbeat settings
  void configureHeartbeat({
    Duration? interval,
    int? maxMissed,
  }) {
    bool restartHeartbeat = false;

    if (interval != null && interval != _heartbeatInterval) {
      _heartbeatInterval = interval;
      restartHeartbeat = true;
    }

    if (maxMissed != null) {
      _maxMissedHeartbeats = maxMissed;
    }

    debugPrint('Heartbeat settings updated: interval=${_heartbeatInterval.inSeconds}s, maxMissed=$_maxMissedHeartbeats');

    // Restart heartbeat if needed and connected
    if (restartHeartbeat && _isConnected) {
      _startHeartbeat();
    }
  }

  // Get current connection status
  SocketConnectionStatus getConnectionStatus() {
    return _connectionStatus;
  }

  // Manually send a ping to test connection and measure latency
  void testConnection() {
    if (!_isConnected) {
      debugPrint('Cannot test connection: not connected');
      return;
    }

    _sendPing();
    debugPrint('Connection test initiated');
  }

  // Clear connection statistics
  void clearConnectionStats() {
    _latencyHistory.clear();
    _totalPings = 0;
    _totalPongs = 0;
    _totalReconnects = 0;
    _totalMessages = 0;
    _lastError = '';

    debugPrint('Connection statistics cleared');
  }

  // Get connection statistics
  Map<String, dynamic> getConnectionStats() {
    return {
      'isConnected': _isConnected,
      'connectionStatus': _connectionStatus.toString(),
      'connectedSince': _connectedSince?.toIso8601String(),
      'connectionDuration': _connectedSince != null 
          ? DateTime.now().difference(_connectedSince!).toString() 
          : null,
      'totalReconnects': _totalReconnects,
      'totalMessages': _totalMessages,
      'totalPings': _totalPings,
      'totalPongs': _totalPongs,
      'currentLatency': _latencyMs,
      'averageLatency': getAverageLatency(),
      'latencyHistory': _latencyHistory,
      'missedHeartbeats': _missedHeartbeats,
      'lastError': _lastError,
      'reconnectAttempts': _reconnectAttempts,
      'maxReconnectAttempts': _maxReconnectAttempts,
      'autoReconnect': _autoReconnect,
      'wasEverConnected': _wasConnected,
      'socketUrl': _urlConfigProvider.currentBaseUrlSocket,
      'heartbeatInterval': _heartbeatInterval.inSeconds,
      'reconnectBaseInterval': _baseReconnectInterval.inSeconds,
      'reconnectMaxInterval': _maxReconnectInterval.inSeconds,
    };
  }

  // Get connection quality rating (0-100)
  int getConnectionQuality() {
    if (!_isConnected) return 0;
    if (_latencyHistory.isEmpty) return 50; // Default if no data

    // Calculate average latency
    final avgLatency = getAverageLatency();

    // Calculate quality score based on latency
    // < 50ms: Excellent (90-100)
    // 50-100ms: Good (70-90)
    // 100-200ms: Fair (50-70)
    // 200-500ms: Poor (30-50)
    // > 500ms: Bad (0-30)
    int qualityScore;
    if (avgLatency < 50) {
      qualityScore = 90 + ((50 - avgLatency) * 10 ~/ 50);
    } else if (avgLatency < 100) {
      qualityScore = 70 + ((100 - avgLatency) * 20 ~/ 50);
    } else if (avgLatency < 200) {
      qualityScore = 50 + ((200 - avgLatency) * 20 ~/ 100);
    } else if (avgLatency < 500) {
      qualityScore = 30 + ((500 - avgLatency) * 20 ~/ 300);
    } else {
      qualityScore = math.max(0, 30 - (avgLatency - 500) ~/ 100);
    }

    // Adjust for reconnects and missed heartbeats
    if (_totalReconnects > 0) {
      qualityScore = (qualityScore * 0.9).toInt(); // 10% penalty for each reconnect
    }

    if (_missedHeartbeats > 0) {
      qualityScore = (qualityScore * (1 - (_missedHeartbeats * 0.1))).toInt(); // 10% penalty per missed heartbeat
    }

    return qualityScore.clamp(0, 100);
  }

  // Disconnect from the socket server
  void disconnect() {
    _cancelReconnectTimer();
    if (_isConnected) {
      _socket.disconnect();
      _isConnected = false;
      _updateConnectionStatus(SocketConnectionStatus.disconnected);
    }
  }

  // Dispose resources
  void dispose() {
    debugPrint('Disposing SocketService');

    // Stop timers
    _cancelReconnectTimer();
    _stopHeartbeat();

    // Close all stream controllers
    _connectionStatusController.close();
    _contractGeneratedController.close();
    _paymentReceivedController.close();
    _requestStatusChangedController.close();
    _latencyController.close();

    // Disconnect from socket
    disconnect();

    debugPrint('SocketService disposed');
  }
}
