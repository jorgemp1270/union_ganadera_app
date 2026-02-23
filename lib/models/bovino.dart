/// Minimal public projection returned inside GET /bovinos/{id} for madre/padre.
/// Cross-ownership after compraventa: full record is forbidden (403) but this
/// projection is always provided for genealogy display.
class BovinoPublicProjection {
  final String id;
  final String? folio;
  final String? razaDominante;
  final DateTime? fechaNac;
  final String? sexo;

  BovinoPublicProjection({
    required this.id,
    this.folio,
    this.razaDominante,
    this.fechaNac,
    this.sexo,
  });

  factory BovinoPublicProjection.fromJson(Map<String, dynamic> json) {
    return BovinoPublicProjection(
      id: json['id'],
      folio: json['folio'],
      razaDominante: json['raza_dominante'],
      fechaNac:
          json['fecha_nac'] != null ? DateTime.parse(json['fecha_nac']) : null,
      sexo: json['sexo'],
    );
  }

  String get displayName => folio ?? razaDominante ?? id.substring(0, 8);
}

class Bovino {
  final String id;
  final String usuarioId;
  final String? usuarioOriginalId;
  final String? nombre;
  final String? areteBarcode;
  final String? areteRfid;
  final String? narizStorageKey;
  final String? narizUrl;
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
  final String? folio;

  /// Minimal public projection for madre — present on single‑detail responses.
  final BovinoPublicProjection? madreProjection;

  /// Minimal public projection for padre — present on single‑detail responses.
  final BovinoPublicProjection? padreProjection;

  Bovino({
    required this.id,
    required this.usuarioId,
    this.usuarioOriginalId,
    this.nombre,
    this.areteBarcode,
    this.areteRfid,
    this.narizStorageKey,
    this.narizUrl,
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
    this.folio,
    this.madreProjection,
    this.padreProjection,
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
      narizUrl: json['nariz_url'],
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
      folio: json['folio'],
      madreProjection:
          json['madre'] != null
              ? BovinoPublicProjection.fromJson(json['madre'])
              : null,
      padreProjection:
          json['padre'] != null
              ? BovinoPublicProjection.fromJson(json['padre'])
              : null,
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
