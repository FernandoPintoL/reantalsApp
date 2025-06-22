import 'package:rentals/models/servicio_basico_model.dart';
import 'tipo_inmueble_model.dart';
import 'user_model.dart';

class InmuebleModel {
  final int id;
  final int userId; // id del propietario
  final String nombre;
  final String? detalle;
  final String numHabitacion;
  final String numPiso;
  final double precio;
  final bool isOcupado;
  final List<Map<String, dynamic>>? accesorios;
  final List<ServicioBasicoModel>? servicios_basicos;
  final int tipoInmuebleId;

  late TipoInmuebleModel? tipoInmueble;
  late UserModel? propietario;

  InmuebleModel({
    this.id = 0,
    this.userId = 0,
    this.nombre = '',
    this.detalle,
    this.numHabitacion = '',
    this.numPiso = '',
    this.precio = 0.0,
    this.isOcupado = false,
    this.accesorios,
    this.servicios_basicos,
    this.tipoInmuebleId = 0,
  });

  factory InmuebleModel.mapToModel(Map<String, dynamic> doc) {
    print('InmuebleModel.mapToModel: ${doc['servicios_basicos']}');
    InmuebleModel model = InmuebleModel(
      id: doc['id'] ?? 0,
      userId: doc['user_id'] ?? 0,
      nombre: doc['nombre'] ?? '',
      detalle: doc['detalle'],
      numHabitacion: doc['num_habitacion'] ?? '',
      numPiso: doc['num_piso'] ?? '',
      precio: double.tryParse(doc['precio']?.toString() ?? '0') ?? 0.0,
      isOcupado: doc['isOcupado'] ?? false,
      accesorios: null,
      servicios_basicos: doc['servicios_basicos'] is List
          ? ServicioBasicoModel.fromJsonList(doc['servicios_basicos'] as List<dynamic>?)
          : null,
      tipoInmuebleId: doc['tipo_inmueble_id'] ?? 0,
    );
    if (doc['tipo_inmueble'] != null) {
      model.tipoInmueble = TipoInmuebleModel.fromJson(doc['tipo_inmueble']);
    } else {
      model.tipoInmueble = null;
    }
    if (doc['propietario'] != null) {
      model.propietario = UserModel.mapToModel(doc['propietario']);
    } else {
      model.propietario = null;
    }
    return model;
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'nombre': nombre,
      'detalle': detalle,
      'num_habitacion': numHabitacion,
      'num_piso': numPiso,
      'precio': precio,
      'isOcupado': isOcupado,
      'accesorios': accesorios ?? null,
      'tipo_inmueble_id': tipoInmuebleId,
      'servicios_basicos': servicios_basicos?.map((servicio) => servicio.toJson()).toList(),
    };
  }
  static List<InmuebleModel> fromList(dynamic data) {
    if (data is List) {
      return data.map((item) => InmuebleModel.mapToModel(item)).toList();
    } else if (data is Map<String, dynamic>) {
      return [InmuebleModel.mapToModel(data)];
    } else {
      return [];
    }
  }
}