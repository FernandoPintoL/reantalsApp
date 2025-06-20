import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/HandlerDateTime.dart';

class SessionModelo{
  int? id;
  int? userId;
  String? status;
  Timestamp? createdAt;
  Timestamp? updatedAt;

  SessionModelo({
    this.id,
    this.userId,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  SessionModelo.mapToModel(Map<String, dynamic> json) {
    id = int.tryParse(json['id'].toString()) ?? 0;
    userId = int.tryParse(json['user_id'].toString()) ?? 0;
    status = json['status'] ?? '';
    createdAt = json['created_at'] != null
        ? HandlerDateTime.getDateTimeOfString(json['created_at'].toString())
        : HandlerDateTime.getDateTimeNow();
    updatedAt = json['updated_at'] != null
        ? HandlerDateTime.getDateTimeOfString(json['updated_at'].toString())
        : HandlerDateTime.getDateTimeNow();
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['status'] = status;
    data['created_at'] = HandlerDateTime.getDateTimeOfDT(createdAt?? HandlerDateTime.getDateTimeNow());
    data['updated_at'] = HandlerDateTime.getDateTimeOfDT(updatedAt?? HandlerDateTime.getDateTimeNow());
    return data;
  }

}