import 'dart:async';
import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import '../services/websocket_admin_service.dart';

class WebSocketStatusWidget extends StatefulWidget {
  final WebSocketAdminService adminService;
  final bool showControls;
  final bool showStats;

  const WebSocketStatusWidget({
    Key? key,
    required this.adminService,
    this.showControls = true,
    this.showStats = false,
  }) : super(key: key);

  @override
  State<WebSocketStatusWidget> createState() => _WebSocketStatusWidgetState();
}

class _WebSocketStatusWidgetState extends State<WebSocketStatusWidget> {
  late StreamSubscription<SocketConnectionStatus> _statusSubscription;
  late StreamSubscription<Map<String, dynamic>> _adminEventsSubscription;
  SocketConnectionStatus _status = SocketConnectionStatus.disconnected;
  Map<String, dynamic> _stats = {};
  Timer? _statsTimer;

  @override
  void initState() {
    super.initState();
    _status = widget.adminService.getConnectionStatus();
    _stats = widget.adminService.getConnectionStats();

    // Listen to connection status changes
    _statusSubscription = widget.adminService.connectionStatus.listen((status) {
      setState(() {
        _status = status;
      });
    });

    // Listen to admin events
    _adminEventsSubscription = widget.adminService.adminEvents.listen((event) {
      // Update stats when admin events occur
      if (widget.showStats) {
        setState(() {
          _stats = widget.adminService.getConnectionStats();
        });
      }
    });

    // Periodically update stats if showing stats
    if (widget.showStats) {
      _statsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) {
          setState(() {
            _stats = widget.adminService.getConnectionStats();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _statusSubscription.cancel();
    _adminEventsSubscription.cancel();
    _statsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _buildStatusIndicator(),
                const SizedBox(width: 8),
                Text(
                  'WebSocket: ${_status.toString().split('.').last}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (widget.showControls) _buildControls(),
              ],
            ),
            if (widget.showStats) ...[
              const SizedBox(height: 16),
              _buildStats(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    Color color;
    switch (_status) {
      case SocketConnectionStatus.connected:
        color = Colors.green;
        break;
      case SocketConnectionStatus.connecting:
      case SocketConnectionStatus.reconnecting:
        color = Colors.orange;
        break;
      case SocketConnectionStatus.disconnected:
        color = Colors.grey;
        break;
      case SocketConnectionStatus.error:
        color = Colors.red;
        break;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Reconnect',
          onPressed: () => widget.adminService.reconnect(),
        ),
        IconButton(
          icon: Icon(_status == SocketConnectionStatus.connected 
              ? Icons.link_off 
              : Icons.link),
          tooltip: _status == SocketConnectionStatus.connected 
              ? 'Disconnect' 
              : 'Connect',
          onPressed: () {
            if (_status == SocketConnectionStatus.connected) {
              widget.adminService.disconnect();
            } else {
              widget.adminService.connect();
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () => _showSettingsDialog(context),
        ),
      ],
    );
  }

  Widget _buildStats() {
    // Get connection quality
    final quality = widget.adminService.getConnectionQuality();
    final avgLatency = widget.adminService.getAverageLatency();

    // Determine quality color
    Color qualityColor;
    if (quality >= 90) {
      qualityColor = Colors.green;
    } else if (quality >= 70) {
      qualityColor = Colors.lightGreen;
    } else if (quality >= 50) {
      qualityColor = Colors.orange;
    } else if (quality >= 30) {
      qualityColor = Colors.deepOrange;
    } else {
      qualityColor = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Connection Statistics:', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),

        // Connection quality indicator
        Row(
          children: [
            Text('Connection Quality: '),
            Container(
              width: 50,
              height: 20,
              decoration: BoxDecoration(
                color: qualityColor,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                '$quality%',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.speed, size: 16),
              tooltip: 'Test Connection',
              onPressed: () => widget.adminService.testConnection(),
            ),
          ],
        ),

        // Latency information
        Row(
          children: [
            Text('Current Latency: ${_stats['currentLatency'] ?? 0}ms'),
            const SizedBox(width: 8),
            Text('Avg: ${avgLatency}ms'),
          ],
        ),

        // Basic connection info
        Text('Connected since: ${_stats['connectedSince'] ?? 'N/A'}'),
        Text('Connection duration: ${_stats['connectionDuration'] ?? 'N/A'}'),
        Text('Total reconnects: ${_stats['totalReconnects'] ?? 0}'),
        Text('Total messages: ${_stats['totalMessages'] ?? 0}'),
        Text('Total pings: ${_stats['totalPings'] ?? 0}'),
        Text('Total pongs: ${_stats['totalPongs'] ?? 0}'),

        // Error information
        Text('Last error: ${_stats['lastError']?.isNotEmpty == true ? _stats['lastError'] : 'None'}'),

        // Reconnection info
        Text('Auto-reconnect: ${_stats['autoReconnect'] == true ? 'Enabled' : 'Disabled'}'),
        Text('Reconnect attempts: ${_stats['reconnectAttempts'] ?? 0}/${_stats['maxReconnectAttempts'] ?? 0}'),
        Text('Missed heartbeats: ${_stats['missedHeartbeats'] ?? 0}/${_stats['maxMissedHeartbeats'] ?? 0}'),

        // Clear stats button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Clear Stats'),
            onPressed: () => widget.adminService.clearConnectionStats(),
          ),
        ),
      ],
    );
  }

  void _showSettingsDialog(BuildContext context) {
    bool autoReconnect = _stats['autoReconnect'] ?? true;
    int maxAttempts = _stats['maxReconnectAttempts'] ?? 5;
    int reconnectIntervalSeconds = _stats['reconnectBaseInterval'] != null 
        ? (_stats['reconnectBaseInterval'] as int) 
        : 3;
    int heartbeatIntervalSeconds = _stats['heartbeatInterval'] != null 
        ? (_stats['heartbeatInterval'] as int) 
        : 30;
    int maxMissedHeartbeats = _stats['maxMissedHeartbeats'] != null 
        ? (_stats['maxMissedHeartbeats'] as int) 
        : 2;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('WebSocket Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reconnection settings
                  Text('Reconnection Settings', 
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  SwitchListTile(
                    title: const Text('Auto-reconnect'),
                    value: autoReconnect,
                    onChanged: (value) {
                      setState(() {
                        autoReconnect = value;
                      });
                    },
                  ),

                  ListTile(
                    title: const Text('Max reconnect attempts'),
                    trailing: SizedBox(
                      width: 50,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        controller: TextEditingController(text: maxAttempts.toString()),
                        onChanged: (value) {
                          maxAttempts = int.tryParse(value) ?? maxAttempts;
                        },
                      ),
                    ),
                  ),

                  ListTile(
                    title: const Text('Reconnect interval (seconds)'),
                    trailing: SizedBox(
                      width: 50,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        controller: TextEditingController(text: reconnectIntervalSeconds.toString()),
                        onChanged: (value) {
                          reconnectIntervalSeconds = int.tryParse(value) ?? reconnectIntervalSeconds;
                        },
                      ),
                    ),
                  ),

                  const Divider(),

                  // Heartbeat settings
                  Text('Heartbeat Settings', 
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  ListTile(
                    title: const Text('Heartbeat interval (seconds)'),
                    subtitle: const Text('Time between heartbeats'),
                    trailing: SizedBox(
                      width: 50,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        controller: TextEditingController(text: heartbeatIntervalSeconds.toString()),
                        onChanged: (value) {
                          heartbeatIntervalSeconds = int.tryParse(value) ?? heartbeatIntervalSeconds;
                        },
                      ),
                    ),
                  ),

                  ListTile(
                    title: const Text('Max missed heartbeats'),
                    subtitle: const Text('Before reconnecting'),
                    trailing: SizedBox(
                      width: 50,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        controller: TextEditingController(text: maxMissedHeartbeats.toString()),
                        onChanged: (value) {
                          maxMissedHeartbeats = int.tryParse(value) ?? maxMissedHeartbeats;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Configure reconnect settings
                  widget.adminService.configureReconnect(
                    autoReconnect: autoReconnect,
                    maxAttempts: maxAttempts,
                    interval: Duration(seconds: reconnectIntervalSeconds),
                  );

                  // Skip heartbeat settings for now due to compiler issues

                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
