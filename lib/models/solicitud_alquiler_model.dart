import 'package:cloud_firestore/cloud_firestore.dart';
import 'inmueble_model.dart';
import 'user_model.dart';
import 'servicio_basico_model.dart';
import '../utils/HandlerDateTime.dart';

class SolicitudAlquilerModel {
  int id;
  int inmuebleId;
  int userId;
  String estado;
  List<ServicioBasicoModel> serviciosBasicos;
  String? mensaje;
  Timestamp? createdAt;
  Timestamp? updatedAt;

  // Relaciones
  InmuebleModel? inmueble;
  UserModel? cliente;

  SolicitudAlquilerModel({
    this.id = 0,
    required this.inmuebleId,
    required this.userId,
    this.estado = 'pendiente',
    required this.serviciosBasicos,
    this.mensaje,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    this.inmueble,
    this.cliente,
  }) : createdAt = createdAt ?? HandlerDateTime.getDateTimeNow(),
       updatedAt = updatedAt ?? HandlerDateTime.getDateTimeNow();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inmueble_id': inmuebleId,
      'user_id': userId,
      'estado': estado,
      'servicios_basicos': serviciosBasicos.map((servicio) => servicio.toJson()).toList(),
      'mensaje': mensaje,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'inmueble': inmueble?.toMap(),
      'cliente': cliente?.toMap(),
    };
  }

  factory SolicitudAlquilerModel.fromMap(Map<String, dynamic> map) {
    SolicitudAlquilerModel model = SolicitudAlquilerModel(
      id: map['id'] ?? 0,
      inmuebleId: map['inmueble_id'] ?? 0,
      userId: map['user_id'] ?? 0,
      estado: map['estado'] ?? 'pendiente',
      serviciosBasicos: map['servicios_basicos'] != null
          ? ServicioBasicoModel.fromJsonList(map['servicios_basicos'])
          : [],
      mensaje: map['mensaje'],
      createdAt: map['created_at'] is Timestamp ? map['created_at'] : null,
      updatedAt: map['updated_at'] is Timestamp ? map['updated_at'] : null,
    );

    if (map['inmueble'] != null) {
      model.inmueble = InmuebleModel.mapToModel(map['inmueble']);
    }

    if (map['cliente'] != null) {
      model.cliente = UserModel.mapToModel(map['cliente']);
    }

    return model;
  }

  static List<SolicitudAlquilerModel> fromJsonList(dynamic jsonList) {
    if (jsonList is List) {
      return jsonList.map((item) => SolicitudAlquilerModel.fromMap(item)).toList();
    } else if (jsonList is Map<String, dynamic>) {
      return [SolicitudAlquilerModel.fromMap(jsonList)];
    } else {
      return [];
    }
  }
}