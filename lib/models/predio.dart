class Predio {
  final String id;
  final String? usuarioId;
  final String? domicilioId;
  final String? claveCatastral;
  final double? superficieTotal;
  final double? latitud;
  final double? longitud;

  Predio({
    required this.id,
    this.usuarioId,
    this.domicilioId,
    this.claveCatastral,
    this.superficieTotal,
    this.latitud,
    this.longitud,
  });

  factory Predio.fromJson(Map<String, dynamic> json) {
    return Predio(
      id: json['id'],
      usuarioId: json['usuario_id'],
      domicilioId: json['domicilio_id'],
      claveCatastral: json['clave_catastral'],
      superficieTotal: json['superficie_total']?.toDouble(),
      latitud: json['latitud']?.toDouble(),
      longitud: json['longitud']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'domicilio_id': domicilioId,
      'clave_catastral': claveCatastral,
      'superficie_total': superficieTotal,
      'latitud': latitud,
      'longitud': longitud,
    }..removeWhere((key, value) => value == null);
  }
}
