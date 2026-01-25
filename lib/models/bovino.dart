class Bovino {
  final String id;
  final String usuarioId;
  final String? areteBarcode;
  final String? areteRfid;
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
    this.areteBarcode,
    this.areteRfid,
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
      areteBarcode: json['arete_barcode'],
      areteRfid: json['arete_rfid'],
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
      'arete_barcode': areteBarcode,
      'arete_rfid': areteRfid,
      'raza_dominante': razaDominante,
      'fecha_nac': fechaNac?.toIso8601String().split('T')[0],
      'sexo': sexo,
      'peso_nac': pesoNac,
      'peso_actual': pesoActual,
      'proposito': proposito,
    }..removeWhere((key, value) => value == null);
  }
}
