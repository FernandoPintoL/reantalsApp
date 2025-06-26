import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/socket_service.dart';

class NotificationBadge extends StatefulWidget {
  const NotificationBadge({Key? key}) : super(key: key);

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  int _unreadCount = 0;
  late SocketService _socketService;
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _socketService = Provider.of<SocketService>(context, listen: false);

    // Listen to contract generation events
    _subscriptions.add(_socketService.onContractGenerated.listen((_) {
      _incrementUnreadCount();
    }));

    // Listen to payment received events
    _subscriptions.add(_socketService.onPaymentReceived.listen((_) {
      _incrementUnreadCount();
    }));

    // Listen to request status changed events
    _subscriptions.add(_socketService.onRequestStatusChanged.listen((_) {
      _incrementUnreadCount();
    }));

    // Add some unread notifications for testing in development mode
    assert(() {
      _unreadCount = 3; // Start with 3 unread notifications for testing
      return true;
    }());
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  void _incrementUnreadCount() {
    setState(() {
      _unreadCount++;
    });
  }

  void _resetUnreadCount() {
    setState(() {
      _unreadCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            _resetUnreadCount();
            Navigator.pushNamed(context, '/notifications');
          },
          tooltip: 'Notificaciones',
        ),
        if (_unreadCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
