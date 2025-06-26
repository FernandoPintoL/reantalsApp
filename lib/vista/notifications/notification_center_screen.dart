import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../services/socket_service.dart';
import '../../models/user_model.dart';
import '../../controllers_providers/authenticated_provider.dart';

class NotificationItem {
  final int id;
  final String title;
  final String body;
  final String payload;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
    required this.timestamp,
    this.isRead = false,
  });
}

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({Key? key}) : super(key: key);

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final List<NotificationItem> _notifications = [];
  UserModel? _currentUser;
  late SocketService _socketService;
  late NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _socketService = Provider.of<SocketService>(context, listen: false);
    _notificationService = Provider.of<NotificationService>(context, listen: false);
    _currentUser = Provider.of<AuthenticatedProvider>(context, listen: false).userActual;

    // Listen to contract generation events
    _socketService.onContractGenerated.listen((data) {
      _addNotification(
        id: data['contratoId'] ?? 0,
        title: 'Contrato Generado',
        body: 'Se ha generado un contrato para la propiedad: ${data['propertyName'] ?? ""}',
        payload: 'contract_generated_${data['contratoId'] ?? 0}',
      );
    });

    // Listen to payment received events
    _socketService.onPaymentReceived.listen((data) {
      _addNotification(
        id: data['contratoId'] ?? 0,
        title: 'Pago Recibido',
        body: 'Se ha recibido un pago de \$${data['amount']?.toStringAsFixed(2) ?? "0.00"} para la propiedad: ${data['propertyName'] ?? ""}',
        payload: 'payment_received_${data['contratoId'] ?? 0}',
      );
    });

    // Listen to request status changed events
    _socketService.onRequestStatusChanged.listen((data) {
      String statusText;
      final status = data['status']?.toString().toLowerCase() ?? '';
      
      switch (status) {
        case 'aprobada':
          statusText = 'aprobada';
          break;
        case 'rechazada':
          statusText = 'rechazada';
          break;
        case 'anulada':
          statusText = 'anulada';
          break;
        case 'contrato_generado':
          statusText = 'procesada y se ha generado un contrato';
          break;
        case 'contrato_aprobado':
          statusText = 'aprobada y el contrato ha sido confirmado';
          break;
        case 'contrato_rechazado':
          statusText = 'rechazada y el contrato ha sido cancelado';
          break;
        default:
          statusText = status;
      }

      _addNotification(
        id: data['solicitudId'] ?? 0,
        title: 'Solicitud de Alquiler Actualizada',
        body: 'Tu solicitud para la propiedad "${data['propertyName'] ?? ""}" ha sido $statusText',
        payload: 'request_status_${data['solicitudId'] ?? 0}',
      );
    });

    // Add some sample notifications for testing
    _addSampleNotifications();
  }

  void _addNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) {
    setState(() {
      _notifications.insert(
        0,
        NotificationItem(
          id: id,
          title: title,
          body: body,
          payload: payload,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void _addSampleNotifications() {
    // Only add sample notifications in development mode
    assert(() {
      _addNotification(
        id: 1001,
        title: 'Contrato Generado',
        body: 'Se ha generado un contrato para la propiedad: Apartamento en Miraflores',
        payload: 'contract_generated_1001',
      );
      _addNotification(
        id: 1002,
        title: 'Pago Recibido',
        body: 'Se ha recibido un pago de \$1,200.00 para la propiedad: Casa en San Isidro',
        payload: 'payment_received_1002',
      );
      _addNotification(
        id: 1003,
        title: 'Solicitud de Alquiler Actualizada',
        body: 'Tu solicitud para la propiedad "Departamento en San Borja" ha sido aprobada',
        payload: 'request_status_1003',
      );
      return true;
    }());
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
  }

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
  }

  void _handleNotificationTap(NotificationItem notification) {
    // Mark as read
    setState(() {
      notification.isRead = true;
    });

    // Handle navigation based on payload
    final payload = notification.payload;
    if (payload.startsWith('contract_generated_')) {
      // Navigate to contract details
      final contratoId = int.tryParse(payload.split('_').last) ?? 0;
      if (contratoId > 0) {
        // Navigate to contract details screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navegando al contrato #$contratoId')),
        );
      }
    } else if (payload.startsWith('payment_received_')) {
      // Navigate to payment details
      final contratoId = int.tryParse(payload.split('_').last) ?? 0;
      if (contratoId > 0) {
        // Navigate to payment details screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navegando al pago del contrato #$contratoId')),
        );
      }
    } else if (payload.startsWith('request_status_')) {
      // Navigate to request details
      final solicitudId = int.tryParse(payload.split('_').last) ?? 0;
      if (solicitudId > 0) {
        // Navigate to request details screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navegando a la solicitud #$solicitudId')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de Notificaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Marcar todas como leídas',
            onPressed: _markAllAsRead,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Borrar todas',
            onPressed: _clearAll,
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes notificaciones',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: notification.isRead ? null : Colors.blue.shade50,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notification.isRead ? Colors.grey : Colors.blue,
                      child: Icon(
                        _getNotificationIcon(notification.payload),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification.body),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(notification.timestamp),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () => _handleNotificationTap(notification),
                  ),
                );
              },
            ),
    );
  }

  IconData _getNotificationIcon(String payload) {
    if (payload.startsWith('contract_generated_')) {
      return Icons.description;
    } else if (payload.startsWith('payment_received_')) {
      return Icons.payment;
    } else if (payload.startsWith('request_status_')) {
      return Icons.home;
    } else {
      return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else {
      return 'Justo ahora';
    }
  }
}