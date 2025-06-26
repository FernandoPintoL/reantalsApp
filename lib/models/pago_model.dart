class PagoModel{
  int id;
  int contratoId;
  String? blockChainId;
  DateTime fechaPago;
  double monto;
  String estado;
  String? descripcion;
  List<Map<String, dynamic>>? historialAcciones;

  PagoModel({
    this.id = 0,
    this.contratoId = 0,
    this.blockChainId,
    required this.fechaPago,
    this.monto = 0.0,
    this.estado = '',
    this.descripcion,
    this.historialAcciones,
  });

  factory PagoModel.fromJson(Map<String, dynamic> json) {
    return PagoModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      contratoId: int.tryParse(json['contrato_id'].toString()) ?? 0,
      blockChainId: json['blockchain_id'],
      fechaPago: DateTime.parse(json['fecha_pago']),
      monto: (json['monto'] is num) ? (json['monto'] as num).toDouble() : 0.0,
      estado: json['estado'] ?? '',
      descripcion: json['descripcion'],
      historialAcciones: json['historial_acciones'] != null
          ? List<Map<String, dynamic>>.from(json['historial_acciones'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contrato_id': contratoId,
      'blockchain_id': blockChainId,
      'fecha_pago': fechaPago.toIso8601String(),
      'monto': monto,
      'estado': estado,
      'descripcion': descripcion,
      'historial_acciones': historialAcciones ?? [],
    };
  }
  static List<PagoModel> fromList(dynamic list) {
    if (list is List) {
      return list.map((item) => PagoModel.fromJson(item)).toList();
    } else if (list is Map<String, dynamic>) {
      return [PagoModel.fromJson(list)];
    } else {
      return [];
    }
  }
}
