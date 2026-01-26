class Bovino {
  final String id;
  final String usuarioId;
  final String? usuarioOriginalId;
  final String? nombre;
  final String? areteBarcode;
  final String? areteRfid;
  final String? narizStorageKey;
  final String? madreId;
  final String? padreId;
  final String? predioId;
  final String? razaDominante;
  final DateTime? fechaNac;
  final String? sexo;
  final double? pesoNac;
  final double? pesoActual;
  final String? proposito;
  final String status;

  Bovino({
    required this.id,
    required this.usuarioId,
    this.usuarioOriginalId,
    this.nombre,
    this.areteBarcode,
    this.areteRfid,
    this.narizStorageKey,
    this.madreId,
    this.padreId,
    this.predioId,
    this.razaDominante,
    this.fechaNac,
    this.sexo,
    this.pesoNac,
    this.pesoActual,
    this.proposito,
    required this.status,
  });

  factory Bovino.fromJson(Map<String, dynamic> json) {
    return Bovino(
      id: json['id'],
      usuarioId: json['usuario_id'],
      usuarioOriginalId: json['usuario_original_id'],
      nombre: json['nombre'],
      areteBarcode: json['arete_barcode'],
      areteRfid: json['arete_rfid'],
      narizStorageKey: json['nariz_storage_key'],
      madreId: json['madre_id'],
      padreId: json['padre_id'],
      predioId: json['predio_id'],
      razaDominante: json['raza_dominante'],
      fechaNac:
          json['fecha_nac'] != null ? DateTime.parse(json['fecha_nac']) : null,
      sexo: json['sexo'],
      pesoNac: json['peso_nac']?.toDouble(),
      pesoActual: json['peso_actual']?.toDouble(),
      proposito: json['proposito'],
      status: json['status'] ?? 'activo',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'arete_barcode': areteBarcode,
      'arete_rfid': areteRfid,
      'madre_id': madreId,
      'padre_id': padreId,
      'predio_id': predioId,
      'raza_dominante': razaDominante,
      'fecha_nac': fechaNac?.toIso8601String().split('T')[0],
      'sexo': sexo,
      'peso_nac': pesoNac,
      'peso_actual': pesoActual,
      'proposito': proposito,
    }..removeWhere((key, value) => value == null);
  }
}
