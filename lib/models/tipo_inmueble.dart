class TipoInmuebleModel {
  int id;
  String nombre;
  String? detalle;

  TipoInmuebleModel({
    this.id = 0,
    this.nombre = '',
    this.detalle,
  });

  factory TipoInmuebleModel.fromJson(Map<String, dynamic> json) {
    return TipoInmuebleModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      nombre: json['nombre'] ?? '',
      detalle: json['detalle'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'detalle': detalle,
    };
  }
  static List<TipoInmuebleModel> fromList(dynamic list) {
    if (list is List) {
      return list.map((item) => TipoInmuebleModel.fromJson(item)).toList();
    } else if (list is Map<String, dynamic>) {
      return [TipoInmuebleModel.fromJson(list)];
    } else {
      return [];
    }
  }
}