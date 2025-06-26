import 'package:cloud_firestore/cloud_firestore.dart';
import 'inmueble_model.dart';
import 'user_model.dart';
import 'solicitud_alquiler_model.dart';
import 'condicional_model.dart';
import '../utils/HandlerDateTime.dart';

class ContratoModel {
  int id;
  int inmuebleId;
  int userId; // id del cliente
  int? solicitudId;
  DateTime fechaInicio;
  DateTime fechaFin;
  double monto;
  String? detalle;
  String estado = '';
  List<CondicionalModel> condicionales;
  String? blockchainAddress;
  String? blockchainTxHash;
  bool clienteAprobado;
  DateTime? fechaPago;
  Timestamp? createdAt;
  Timestamp? updatedAt;

  // Relaciones
  late UserModel? cliente;
  late InmuebleModel? inmueble;
  late SolicitudAlquilerModel? solicitud;

  // Getter para obtener el propietario del inmueble
  UserModel? get propietario {
    if (inmueble != null && inmueble!.propietario != null) {
      return inmueble!.propietario;
    }
    return null;
  }

  ContratoModel({
    this.id = 0,
    this.inmuebleId = 0,
    this.userId = 0,
    this.solicitudId,
    required this.fechaInicio,
    required this.fechaFin,
    this.monto = 0.0,
    this.detalle,
    this.estado = '',
    this.condicionales = const [],
    this.blockchainAddress,
    this.blockchainTxHash,
    this.clienteAprobado = false,
    this.fechaPago,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    this.solicitud,
    this.cliente,
    this.inmueble,
  }) : createdAt = createdAt ?? HandlerDateTime.getDateTimeNow(),
       updatedAt = updatedAt ?? HandlerDateTime.getDateTimeNow();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inmueble_id': inmuebleId,
      'user_id': userId,
      'solicitud_id': solicitudId,
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_fin': fechaFin.toIso8601String(),
      'monto': monto,
      'detalle': detalle,
      'estado': estado,
      'condicionales': condicionales.map((c) => c.toMap()).toList(),
      'blockchain_address': blockchainAddress,
      'blockchain_tx_hash': blockchainTxHash,
      'cliente_aprobado': clienteAprobado,
      'fecha_pago': fechaPago?.toIso8601String()
    };
  }

  factory ContratoModel.fromMap(Map<String, dynamic> map) {
    print('ContratoModel.fromMap - Input: ${map['monto']}');
    ContratoModel model = ContratoModel(
      id: map['id'] ?? 0,
      inmuebleId: map['inmueble_id'] ?? 0,
      userId: map['user_id'] ?? 0,
      solicitudId: map['solicitud_id'],
      fechaInicio: DateTime.parse(map['fecha_inicio']),
      fechaFin: DateTime.parse(map['fecha_fin']),
      monto: double.tryParse(map['monto']?.toString() ?? '0') ?? 0.0,
      detalle: map['detalle'],
      estado: map['estado'] ?? '',
      condicionales: CondicionalModel.fromJsonList(map['condicionales']),
      blockchainAddress: map['blockchain_address'],
      blockchainTxHash: map['blockchain_tx_hash'],
      clienteAprobado: map['cliente_aprobado'] ?? false,
      fechaPago: map['fecha_pago'] != null ? DateTime.parse(map['fecha_pago']) : null,
      createdAt: map['created_at'] is Timestamp ? map['created_at'] : null,
      updatedAt: map['updated_at'] is Timestamp ? map['updated_at'] : null,
    );

    if (map['user'] != null) {
      model.cliente = UserModel.mapToModel(map['user']);
    } else {
      model.cliente = null;
    }

    if (map['inmueble'] != null) {
      model.inmueble = InmuebleModel.mapToModel(map['inmueble']);
    } else {
      model.inmueble = null;
    }

    if (map['solicitud'] != null) {
      model.solicitud = SolicitudAlquilerModel.fromMap(map['solicitud']);
    }

    return model;
  }

  static List<ContratoModel> fromJsonList(dynamic jsonList) {
    if (jsonList is List) {
      return jsonList.map((item) => ContratoModel.fromMap(item)).toList();
    } else if (jsonList is Map<String, dynamic>) {
      return [ContratoModel.fromMap(jsonList)];
    } else {
      return [];
    }
  }
}
