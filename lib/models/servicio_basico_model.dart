import 'dart:convert';

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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
    };
  }

  static List<ServicioBasicoModel> fromJsonList(dynamic jsonList) {
    // Si es null, retorna lista vacía
    if (jsonList == null) return [];

    // Si es String (JSON sin parsear), intenta convertirlo a List
    if (jsonList is String) {
      try {
        jsonList = json.decode(jsonList) as List;
      } catch (e) {
        print('Error al decodificar JSON: $e');
        return [];
      }
    }

    // Si ya es una List, procesa los items
    if (jsonList is List) {
      return jsonList.map((item) {
        try {
          // Si el item es un Map, pero no está tipado como <String, dynamic>
          if (item is Map) {
            final jsonItem = Map<String, dynamic>.from(item); // Conversión segura
            return ServicioBasicoModel.fromJson(jsonItem);
          }
          return ServicioBasicoModel(nombre: 'Inválido', isSelected: false);
        } catch (e) {
          return ServicioBasicoModel(nombre: 'Error', isSelected: false);
        }
      }).toList();
    }
    return [];
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