class ServicioBasicoModel {
  int id;
  String nombre;
  String? descripcion;
  bool isSelected;

  ServicioBasicoModel({
    this.id = 0,
    required this.nombre,
    this.descripcion,
    this.isSelected = false,
  });

  factory ServicioBasicoModel.fromJson(Map<String, dynamic> json) {
    return ServicioBasicoModel(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      isSelected: json['is_selected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'is_selected': isSelected,
    };
  }

  static List<ServicioBasicoModel> fromJsonList(dynamic jsonList) {
    if (jsonList == null) return [];
    return List<ServicioBasicoModel>.from(
      jsonList.map((item) => ServicioBasicoModel.fromJson(item)),
    );
  }

  // Default list of basic services
  static List<ServicioBasicoModel> getDefaultServicios() {
    return [
      ServicioBasicoModel(id: 1, nombre: 'Agua', descripcion: 'Servicio de agua potable'),
      ServicioBasicoModel(id: 2, nombre: 'Luz', descripcion: 'Servicio de electricidad'),
      ServicioBasicoModel(id: 3, nombre: 'Gas', descripcion: 'Servicio de gas natural'),
      ServicioBasicoModel(id: 4, nombre: 'Internet', descripcion: 'Servicio de internet'),
      ServicioBasicoModel(id: 5, nombre: 'Cable', descripcion: 'Servicio de televisión por cable'),
      ServicioBasicoModel(id: 6, nombre: 'Limpieza', descripcion: 'Servicio de limpieza'),
      ServicioBasicoModel(id: 7, nombre: 'Seguridad', descripcion: 'Servicio de seguridad'),
    ];
  }
}