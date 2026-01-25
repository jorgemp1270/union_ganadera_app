class DocumentFile {
  final String id;
  final String docType;
  final String originalFilename;
  final DateTime createdAt;
  final bool authored;
  final String? downloadUrl;

  DocumentFile({
    required this.id,
    required this.docType,
    required this.originalFilename,
    required this.createdAt,
    required this.authored,
    this.downloadUrl,
  });

  factory DocumentFile.fromJson(Map<String, dynamic> json) {
    return DocumentFile(
      id: json['id'],
      docType: json['doc_type'],
      originalFilename: json['original_filename'],
      createdAt: DateTime.parse(json['created_at']),
      authored: json['authored'] ?? false,
      downloadUrl: json['download_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doc_type': docType,
      'original_filename': originalFilename,
      'created_at': createdAt.toIso8601String(),
      'authored': authored,
      'download_url': downloadUrl,
    };
  }
}

enum DocType {
  identificacion,
  comprobanteDomicilio,
  predio,
  cedulaVeterinario,
  otro,
}

extension DocTypeExtension on DocType {
  String get value {
    switch (this) {
      case DocType.identificacion:
        return 'identificacion';
      case DocType.comprobanteDomicilio:
        return 'comprobante_domicilio';
      case DocType.predio:
        return 'predio';
      case DocType.cedulaVeterinario:
        return 'cedula_veterinario';
      case DocType.otro:
        return 'otro';
    }
  }

  String get displayName {
    switch (this) {
      case DocType.identificacion:
        return 'Identificación (INE)';
      case DocType.comprobanteDomicilio:
        return 'Comprobante de Domicilio';
      case DocType.predio:
        return 'Documento de Predio';
      case DocType.cedulaVeterinario:
        return 'Cédula Veterinaria';
      case DocType.otro:
        return 'Otro';
    }
  }
}
