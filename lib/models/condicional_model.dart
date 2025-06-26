import 'dart:convert';
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
      print('Es una lista con ${jsonList.length} elementos');

      return jsonList.map((item) {
        try {
          // Si el item es un Map, pero no está tipado como <String, dynamic>
          if (item is Map) {
            final jsonItem = Map<String, dynamic>.from(item); // Conversión segura
            return CondicionalModel.fromMap(jsonItem);
          }
          print('Item no es un Map: $item (Tipo: ${item.runtimeType})');
          return CondicionalModel(
            id: 0,
            descripcion: '',
            tipoCondicion: '',
            accion: '',
            parametros: {}, // Retorna un modelo vacío si no es un Map
          ); // Retorna un modelo vacío si no es un Map
        } catch (e) {
          print('Error al procesar item: $e');
          return CondicionalModel(
            id: 0,
            descripcion: '',
            tipoCondicion: '',
            accion: '',
            parametros: {}, // Retorna un modelo vacío en caso de error
          ); // Retorna un modelo vacío en caso de error
        }
      }).toList();
    }

    print('El input no es una lista válida');
    return []; // Retorna lista vacía si no es una lista válida
  }
}