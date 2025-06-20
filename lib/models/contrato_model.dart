import 'package:cloud_firestore/cloud_firestore.dart';
import 'inmueble_model.dart';
import 'user_model.dart';
import 'solicitud_alquiler_model.dart';
import '../utils/HandlerDateTime.dart';

class CondicionalModel {
  int id;
  String descripcion;
  String tipoCondicion;
  String accion;
  Map<String, dynamic>? parametros;

  CondicionalModel({
    this.id = 0,
    required this.descripcion,
    required this.tipoCondicion,
    required this.accion,
    this.parametros,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descripcion': descripcion,
      'tipo_condicion': tipoCondicion,
      'accion': accion,
      'parametros': parametros,
    };
  }

  factory CondicionalModel.fromMap(Map<String, dynamic> map) {
    return CondicionalModel(
      id: map['id'] ?? 0,
      descripcion: map['descripcion'] ?? '',
      tipoCondicion: map['tipo_condicion'] ?? '',
      accion: map['accion'] ?? '',
      parametros: map['parametros'],
    );
  }

  static List<CondicionalModel> fromJsonList(dynamic jsonList) {
    if (jsonList is List) {
      return jsonList.map((item) => CondicionalModel.fromMap(item)).toList();
    } else if (jsonList is Map<String, dynamic>) {
      return [CondicionalModel.fromMap(jsonList)];
    } else {
      return [];
    }
  }
}

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
  bool clienteAprobado;
  DateTime? fechaPago;
  Timestamp? createdAt;
  Timestamp? updatedAt;

  // Relaciones
  late UserModel? cliente;
  late InmuebleModel? inmueble;
  late SolicitudAlquilerModel? solicitud;

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
      'cliente_aprobado': clienteAprobado,
      'fecha_pago': fechaPago?.toIso8601String(),
      'created_at': createdAt,
      'updated_at': updatedAt,
      'user': cliente?.toMap(),
      'inmueble': inmueble?.toMap(),
      'solicitud': solicitud?.toMap(),
    };
  }

  factory ContratoModel.fromMap(Map<String, dynamic> map) {
    ContratoModel model = ContratoModel(
      id: map['id'] ?? 0,
      inmuebleId: map['inmueble_id'] ?? 0,
      userId: map['user_id'] ?? 0,
      solicitudId: map['solicitud_id'],
      fechaInicio: DateTime.parse(map['fecha_inicio']),
      fechaFin: DateTime.parse(map['fecha_fin']),
      monto: (map['monto'] is num) ? (map['monto'] as num).toDouble() : 0.0,
      detalle: map['detalle'],
      estado: map['estado'] ?? '',
      condicionales: map['condicionales'] != null
          ? CondicionalModel.fromJsonList(map['condicionales'])
          : [],
      blockchainAddress: map['blockchain_address'],
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
