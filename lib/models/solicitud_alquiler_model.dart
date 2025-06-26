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
  List<ServicioBasicoModel>? servicios_basicos;
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
    required this.servicios_basicos,
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
      'servicios_basicos':
      servicios_basicos?.map((servicio) => servicio.toJson()).toList(),
      'mensaje': mensaje,
    };
  }

  factory SolicitudAlquilerModel.fromMap(Map<String, dynamic> map) {
    SolicitudAlquilerModel model = SolicitudAlquilerModel(
      id: map['id'] ?? 0,
      inmuebleId: map['inmueble_id'] ?? 0,
      userId: map['user_id'] ?? 0,
      estado: map['estado'] ?? 'pendiente',
      servicios_basicos: ServicioBasicoModel.fromJsonList(map['servicios_basicos']),
      mensaje: map['mensaje'],
      createdAt:
          map['created_at'] != null
              ? HandlerDateTime.getDateTimeOfString(
                map['created_at'].toString(),
              )
              : HandlerDateTime.getDateTimeNow(),
      updatedAt:
          map['updated_at'] != null
              ? HandlerDateTime.getDateTimeOfString(
                map['updated_at'].toString(),
              )
              : HandlerDateTime.getDateTimeNow(),
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
      return jsonList
          .map((item) => SolicitudAlquilerModel.fromMap(item))
          .toList();
    } else if (jsonList is Map<String, dynamic>) {
      return [SolicitudAlquilerModel.fromMap(jsonList)];
    } else {
      return [];
    }
  }
}
