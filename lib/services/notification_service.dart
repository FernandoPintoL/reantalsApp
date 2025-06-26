import 'package:flutter/material.dart';

/// Stub implementation of NotificationService that doesn't use flutter_local_notifications
/// This class maintains the same interface but doesn't actually show notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  bool _isInitialized = false;

  // Private constructor
  NotificationService._internal();

  // Factory constructor to return the same instance
  factory NotificationService() {
    return _instance;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    // No actual initialization needed since we're not using notifications
    _isInitialized = true;
    debugPrint('NotificationService stub initialized');
  }

  // Show a basic notification (stub implementation)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    // Log the notification instead of showing it
    debugPrint('NOTIFICATION STUB: ID=$id, Title=$title, Body=$body, Payload=$payload');
  }

  // Show a notification for contract generation (stub implementation)
  Future<void> showContractGeneratedNotification({
    required int solicitudId,
    required String propertyName,
  }) async {
    await showNotification(
      id: solicitudId,
      title: 'Contrato Generado',
      body: 'Se ha generado un contrato para la propiedad: $propertyName',
      payload: 'contract_generated_$solicitudId',
    );
  }

  // Show a notification for payment received (stub implementation)
  Future<void> showPaymentReceivedNotification({
    required int contratoId,
    required String propertyName,
    required double amount,
  }) async {
    await showNotification(
      id: contratoId,
      title: 'Pago Recibido',
      body: 'Se ha recibido un pago de \$${amount.toStringAsFixed(2)} para la propiedad: $propertyName',
      payload: 'payment_received_$contratoId',
    );
  }

  // Show a notification for rental request status change (stub implementation)
  Future<void> showRequestStatusChangedNotification({
    required int solicitudId,
    required String propertyName,
    required String status,
  }) async {
    String statusText;
    switch (status.toLowerCase()) {
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
      default:
        statusText = status;
    }

    await showNotification(
      id: solicitudId,
      title: 'Solicitud de Alquiler Actualizada',
      body: 'Tu solicitud para la propiedad "$propertyName" ha sido $statusText',
      payload: 'request_status_$solicitudId',
    );
  }
}
