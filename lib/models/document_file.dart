/// The most recent admin review for a document.
class DocumentRevision {
  final String id;
  final String documentoId;
  final String adminId;

  /// 'aprobado' | 'rechazado'
  final String status;
  final String? comentario;
  final DateTime fecha;

  DocumentRevision({
    required this.id,
    required this.documentoId,
    required this.adminId,
    required this.status,
    required this.fecha,
    this.comentario,
  });

  factory DocumentRevision.fromJson(Map<String, dynamic> json) {
    return DocumentRevision(
      id: json['id'],
      documentoId: json['documento_id'],
      adminId: json['admin_id'],
      status: json['status'],
      comentario: json['comentario'],
      fecha: DateTime.parse(json['fecha']),
    );
  }
}

class DocumentFile {
  final String id;
  final String docType;
  final String originalFilename;
  final DateTime createdAt;
  final bool authored;
  final String? downloadUrl;
  final DocumentRevision? ultimaRevision;

  DocumentFile({
    required this.id,
    required this.docType,
    required this.originalFilename,
    required this.createdAt,
    required this.authored,
    this.downloadUrl,
    this.ultimaRevision,
  });

  factory DocumentFile.fromJson(Map<String, dynamic> json) {
    return DocumentFile(
      id: json['id'],
      docType: json['doc_type'],
      originalFilename: json['original_filename'],
      createdAt: DateTime.parse(json['created_at']),
      authored: json['authored'] ?? false,
      downloadUrl: json['download_url'],
      ultimaRevision:
          json['ultima_revision'] != null
              ? DocumentRevision.fromJson(json['ultima_revision'])
              : null,
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
  identificacionFrente,
  identificacionReverso,
  comprobanteDomicilio,
  predio,
  cedulaVeterinario,
  fierroDeHerrar,
  otro,
}

extension DocTypeExtension on DocType {
  String get value {
    switch (this) {
      case DocType.identificacionFrente:
        return 'identificacion_frente';
      case DocType.identificacionReverso:
        return 'identificacion_reverso';
      case DocType.comprobanteDomicilio:
        return 'comprobante_domicilio';
      case DocType.predio:
        return 'predio';
      case DocType.cedulaVeterinario:
        return 'cedula_veterinario';
      case DocType.fierroDeHerrar:
        return 'fierro';
      case DocType.otro:
        return 'otro';
    }
  }

  String get displayName {
    switch (this) {
      case DocType.identificacionFrente:
        return 'INE — Frente';
      case DocType.identificacionReverso:
        return 'INE — Reverso';
      case DocType.comprobanteDomicilio:
        return 'Comprobante de Domicilio';
      case DocType.predio:
        return 'Documento de Predio';
      case DocType.cedulaVeterinario:
        return 'Cédula Veterinaria';
      case DocType.fierroDeHerrar:
        return 'Fierro de Herrar';
      case DocType.otro:
        return 'Otro';
    }
  }
}
