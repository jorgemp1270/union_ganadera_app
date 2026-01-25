class Domicilio {
  final String id;
  final String usuarioId;
  final String? calle;
  final String? colonia;
  final String? cp;
  final String? estado;
  final String? municipio;

  Domicilio({
    required this.id,
    required this.usuarioId,
    this.calle,
    this.colonia,
    this.cp,
    this.estado,
    this.municipio,
  });

  factory Domicilio.fromJson(Map<String, dynamic> json) {
    return Domicilio(
      id: json['id'],
      usuarioId: json['usuario_id'],
      calle: json['calle'],
      colonia: json['colonia'],
      cp: json['cp'],
      estado: json['estado'],
      municipio: json['municipio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calle': calle,
      'colonia': colonia,
      'cp': cp,
      'estado': estado,
      'municipio': municipio,
    }..removeWhere((key, value) => value == null);
  }
}
