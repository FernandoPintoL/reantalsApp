class GaleriaInmuebleModel {
  int id;
  int inmuebleId;
  String? photoPath;

  GaleriaInmuebleModel({
    this.id = 0,
    this.inmuebleId = 0,
    this.photoPath,
  });

  factory GaleriaInmuebleModel.fromJson(Map<String, dynamic> json) {
    return GaleriaInmuebleModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      inmuebleId: int.tryParse(json['inmueble_id'].toString()) ?? 0,
      photoPath: json['photo_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inmueble_id': inmuebleId,
      'photo_path': photoPath,
    };
  }
  static List<GaleriaInmuebleModel> fromJsonList(dynamic jsonList) {
    if (jsonList is List) {
      return jsonList.map((item) => GaleriaInmuebleModel.fromJson(item)).toList();
    } else if (jsonList is Map<String, dynamic>) {
      return [GaleriaInmuebleModel.fromJson(jsonList)];
    } else {
      return [];
    }
  }
}