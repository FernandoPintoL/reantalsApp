import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/socket_service.dart';
import '../../services/websocket_admin_service.dart';
import '../../services/UrlConfigProvider.dart';
import '../../widgets/websocket_status_widget.dart';

class WebSocketAdminScreen extends StatefulWidget {
  const WebSocketAdminScreen({Key? key}) : super(key: key);

  @override
  State<WebSocketAdminScreen> createState() => _WebSocketAdminScreenState();
}

class _WebSocketAdminScreenState extends State<WebSocketAdminScreen> {
  final List<Map<String, dynamic>> _adminEvents = [];
  final ScrollController _scrollController = ScrollController();
  int _userId = 0;
  int _propertyId = 0;

  @override
  void initState() {
    super.initState();
    // Listen to admin events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminService = Provider.of<WebSocketAdminService>(
        context,
        listen: false,
      );
      adminService.adminEvents.listen((event) {
        setState(() {
          _adminEvents.add(event);
          // Keep only the last 100 events
          if (_adminEvents.length > 100) {
            _adminEvents.removeAt(0);
          }
        });

        // Scroll to bottom
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminService = Provider.of<WebSocketAdminService>(context);
    final urlConfigProvider = Provider.of<UrlConfigProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Administration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear Events',
            onPressed: () {
              setState(() {
                _adminEvents.clear();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // WebSocket Status Widget
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: WebSocketStatusWidget(
                adminService: adminService,
                showControls: true,
                showStats: true,
              ),
            ),

            // WebSocket Configuration
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WebSocket Configuration',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),

                      // URL Configuration
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'URL Configuration',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),

                          // Display current socket URL
                          Text(
                            'Current Socket URL: ${urlConfigProvider.currentBaseUrlSocket}',
                          ),

                          // Display local and production socket URLs
                          Text(
                            'Local Socket URL: ${urlConfigProvider.baseUrlSocketLocal}',
                          ),
                          Text(
                            'Production Socket URL: ${urlConfigProvider.baseUrlSocketOnline}',
                          ),

                          // Switch between local and production
                          SwitchListTile(
                            title: const Text('Use Production URL'),
                            subtitle: Text(
                              urlConfigProvider.useOnlineUrl
                                  ? 'Using production URL'
                                  : 'Using local URL',
                            ),
                            value: urlConfigProvider.useOnlineUrl,
                            onChanged: (value) async {
                              await urlConfigProvider.setUseOnlineUrl(value);
                              // Reconnect to apply the new URL
                              if (adminService.getConnectionStatus() ==
                                  SocketConnectionStatus.connected) {
                                adminService.reconnect();
                              }
                            },
                          ),
                        ],
                      ),

                      const Divider(),

                      // Reconnection Settings
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reconnection Settings',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),

                          // Get current settings from stats
                          Builder(
                            builder: (context) {
                              final stats = adminService.getConnectionStats();
                              bool autoReconnect =
                                  stats['autoReconnect'] ?? true;
                              int maxAttempts =
                                  stats['maxReconnectAttempts'] ?? 10;
                              int baseIntervalSeconds =
                                  stats['reconnectBaseInterval'] ?? 2;
                              int maxIntervalSeconds =
                                  stats['reconnectMaxInterval'] ?? 120;

                              return Column(
                                children: [
                                  SwitchListTile(
                                    title: const Text('Auto-reconnect'),
                                    subtitle: const Text(
                                      'Automatically reconnect when disconnected',
                                    ),
                                    value: autoReconnect,
                                    onChanged: (value) {
                                      adminService.configureReconnect(
                                        autoReconnect: value,
                                      );
                                    },
                                  ),

                                  ListTile(
                                    title: const Text('Max reconnect attempts'),
                                    subtitle: const Text(
                                      'Maximum number of reconnection attempts',
                                    ),
                                    trailing: SizedBox(
                                      width: 50,
                                      child: TextField(
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                        ),
                                        controller: TextEditingController(
                                          text: maxAttempts.toString(),
                                        ),
                                        onChanged: (value) {
                                          final attempts = int.tryParse(value);
                                          if (attempts != null &&
                                              attempts > 0) {
                                            adminService.configureReconnect(
                                              maxAttempts: attempts,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),

                                  ListTile(
                                    title: const Text(
                                      'Base reconnect interval (seconds)',
                                    ),
                                    subtitle: const Text(
                                      'Initial delay before reconnecting',
                                    ),
                                    trailing: SizedBox(
                                      width: 50,
                                      child: TextField(
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                        ),
                                        controller: TextEditingController(
                                          text: baseIntervalSeconds.toString(),
                                        ),
                                        onChanged: (value) {
                                          final seconds = int.tryParse(value);
                                          if (seconds != null && seconds > 0) {
                                            adminService.configureReconnect(
                                              interval: Duration(
                                                seconds: seconds,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),

                      const Divider(),

                      // Heartbeat Settings
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Heartbeat Settings',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),

                          // Get current settings from stats
                          Builder(
                            builder: (context) {
                              final stats = adminService.getConnectionStats();
                              int heartbeatIntervalSeconds =
                                  stats['heartbeatInterval'] ?? 30;
                              int maxMissedHeartbeats =
                                  stats['maxMissedHeartbeats'] ?? 2;

                              return Column(
                                children: [
                                  ListTile(
                                    title: const Text(
                                      'Heartbeat interval (seconds)',
                                    ),
                                    subtitle: const Text(
                                      'Time between heartbeats',
                                    ),
                                    trailing: SizedBox(
                                      width: 50,
                                      child: TextField(
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                        ),
                                        controller: TextEditingController(
                                          text:
                                              heartbeatIntervalSeconds
                                                  .toString(),
                                        ),
                                        onChanged: (value) {
                                          final seconds = int.tryParse(value);
                                          if (seconds != null && seconds > 0) {
                                            adminService.setHeartbeatSettings(
                                              interval: Duration(
                                                seconds: seconds,
                                              ),
                                            );
                                          }
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
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                        ),
                                        controller: TextEditingController(
                                          text: maxMissedHeartbeats.toString(),
                                        ),
                                        onChanged: (value) {
                                          final missed = int.tryParse(value);
                                          if (missed != null && missed > 0) {
                                            adminService.setHeartbeatSettings(
                                              maxMissed: missed,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Room Management
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room Management',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),

                      // User Room
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'User ID',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _userId = int.tryParse(value) ?? 0;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (_userId > 0) {
                                adminService.joinUserRoom(_userId);
                              }
                            },
                            child: const Text('Join'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (_userId > 0) {
                                adminService.leaveUserRoom(_userId);
                              }
                            },
                            child: const Text('Leave'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Property Room
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Property ID',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _propertyId = int.tryParse(value) ?? 0;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (_propertyId > 0) {
                                adminService.joinPropertyRoom(_propertyId);
                              }
                            },
                            child: const Text('Join'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (_propertyId > 0) {
                                adminService.leavePropertyRoom(_propertyId);
                              }
                            },
                            child: const Text('Leave'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Admin Events Log
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Admin Events Log',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          Text(
                            '${_adminEvents.length} events',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 300, // Fixed height for the log
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _adminEvents.length,
                          itemBuilder: (context, index) {
                            final event = _adminEvents[index];
                            final timestamp = event['timestamp'] ?? '';
                            final type = event['type'] ?? '';

                            // Format the event for display
                            String eventText = '$type';
                            event.forEach((key, value) {
                              if (key != 'type' && key != 'timestamp') {
                                eventText += ' | $key: $value';
                              }
                            });

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${timestamp.substring(11, 19)} ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      eventText,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
