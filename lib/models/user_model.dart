import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/HandlerDateTime.dart';

class UserModel {
  int id;
  String name;
  String email;
  String usernick;
  String numId;
  String telefono;
  String? photoPath;
  String tipoUsuario;
  String tipoCliente;
  String direccion;
  String? walletAddress;
  Timestamp? createdAt;
  Timestamp? updatedAt;

  UserModel({
    this.id = 0,
    this.email = '',
    this.name = '',
    this.usernick = '',
    this.numId = '',
    this.telefono = '',
    this.photoPath,
    this.tipoUsuario = 'cliente',
    this.tipoCliente = 'particular',
    this.direccion = '',
    this.walletAddress,
    Timestamp? createdAt,
    Timestamp? updatedAt
  }) : createdAt = createdAt ?? HandlerDateTime.getDateTimeNow(),
       updatedAt = updatedAt ?? HandlerDateTime.getDateTimeNow();

  // Create a UserModel from a Firebase document
  factory UserModel.mapToModel(Map<String, dynamic> doc) {
    print('mapToModel: ${doc['tipoUsuario']}');
    print('mapToModel: ${doc['propietario']}');
    return UserModel(
      id: doc['id'] ?? 0,
      email: doc['email'] ?? '',
      usernick: doc['usernick'] ?? '',
      name: doc['name'] ?? '',
      numId: doc['num_id'] ?? '',
      telefono: doc['telefono'] ?? '',
      photoPath: doc['photoPath'],
      tipoUsuario: doc['tipo_usuario'] ?? 'cliente',
      tipoCliente: doc['tipo_cliente'] ?? 'particular',
      direccion: doc['direccion'] ?? '',
      createdAt: doc['created_at'] is Timestamp ? doc['created_at'] : null,
      updatedAt: doc['updated_at'] is Timestamp ? doc['updated_at'] : null,
    );
  }

  // Convert UserModel to a map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'usernick': usernick,
      'name': name,
      'num_id': numId,
      'telefono': telefono,
      'photoPath': photoPath,
      'tipo_usuario': tipoUsuario,
      'tipo_cliente': tipoCliente,
      'direccion': direccion
    };
  }
  static List<UserModel> fromList(dynamic list) {
    if (list is List) {
      return list.map((item) => UserModel.mapToModel(item)).toList();
    } else if (list is Map<String, dynamic>) {
      return [UserModel.mapToModel(list)];
    }
    return [];
  }

}