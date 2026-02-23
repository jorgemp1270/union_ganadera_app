// Base event class
class Evento {
  final String id;
  final String bovinoId;
  final DateTime fecha;
  final String? observaciones;

  Evento({
    required this.id,
    required this.bovinoId,
    required this.fecha,
    this.observaciones,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: json['id'],
      bovinoId: json['bovino_id'],
      fecha: DateTime.parse(json['fecha']),
      observaciones: json['observaciones'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bovino_id': bovinoId,
      'fecha': fecha.toIso8601String(),
      'observaciones': observaciones,
    };
  }
}

// Peso event
class PesoEvento extends Evento {
  final double pesoNuevo;
  final double? pesoAnterior;

  PesoEvento({
    required super.id,
    required super.bovinoId,
    required super.fecha,
    super.observaciones,
    required this.pesoNuevo,
    this.pesoAnterior,
  });

  factory PesoEvento.fromJson(Map<String, dynamic> json) {
    return PesoEvento(
      id: json['id'],
      bovinoId: json['bovino_id'],
      fecha: DateTime.parse(json['fecha']),
      observaciones: json['observaciones'],
      pesoNuevo: json['peso_nuevo'].toDouble(),
      pesoAnterior: json['peso_actual']?.toDouble(),
    );
  }
}

// Dieta event
class DietaEvento extends Evento {
  final String alimento;

  DietaEvento({
    required super.id,
    required super.bovinoId,
    required super.fecha,
    super.observaciones,
    required this.alimento,
  });

  factory DietaEvento.fromJson(Map<String, dynamic> json) {
    return DietaEvento(
      id: json['id'],
      bovinoId: json['bovino_id'],
      fecha: DateTime.parse(json['fecha']),
      observaciones: json['observaciones'],
      alimento: json['alimento'],
    );
  }
}

// Vacunacion event
class VacunacionEvento extends Evento {
  final String veterinarioId;
  final String tipo;
  final String lote;
  final String laboratorio;
  final DateTime fechaProx;

  VacunacionEvento({
    required super.id,
    required super.bovinoId,
    required super.fecha,
    super.observaciones,
    required this.veterinarioId,
    required this.tipo,
    required this.lote,
    required this.laboratorio,
    required this.fechaProx,
  });

  factory VacunacionEvento.fromJson(Map<String, dynamic> json) {
    return VacunacionEvento(
      id: json['id'],
      bovinoId: json['bovino_id'],
      fecha: DateTime.parse(json['fecha']),
      observaciones: json['observaciones'],
      veterinarioId: json['veterinario_id'],
      tipo: json['tipo'],
      lote: json['lote'],
      laboratorio: json['laboratorio'],
      fechaProx: DateTime.parse(json['fecha_prox']),
    );
  }
}

// Desparasitacion event
class DesparasitacionEvento extends Evento {
  final String veterinarioId;
  final String medicamento;
  final String dosis;
  final DateTime fechaProx;

  DesparasitacionEvento({
    required super.id,
    required super.bovinoId,
    required super.fecha,
    super.observaciones,
    required this.veterinarioId,
    required this.medicamento,
    required this.dosis,
    required this.fechaProx,
  });

  factory DesparasitacionEvento.fromJson(Map<String, dynamic> json) {
    return DesparasitacionEvento(
      id: json['id'],
      bovinoId: json['bovino_id'],
      fecha: DateTime.parse(json['fecha']),
      observaciones: json['observaciones'],
      veterinarioId: json['veterinario_id'],
      medicamento: json['medicamento'],
      dosis: json['dosis'],
      fechaProx: DateTime.parse(json['fecha_prox']),
    );
  }
}

// Laboratorio event
class LaboratorioEvento extends Evento {
  final String veterinarioId;
  final String tipo;
  final String resultado;

  LaboratorioEvento({
    required super.id,
    required super.bovinoId,
    required super.fecha,
    super.observaciones,
    required this.veterinarioId,
    required this.tipo,
    required this.resultado,
  });

  factory LaboratorioEvento.fromJson(Map<String, dynamic> json) {
    return LaboratorioEvento(
      id: json['id'],
      bovinoId: json['bovino_id'],
      fecha: DateTime.parse(json['fecha']),
      observaciones: json['observaciones'],
      veterinarioId: json['veterinario_id'],
      tipo: json['tipo'],
      resultado: json['resultado'],
    );
  }
}

// Compraventa event
class CompraventaEvento extends Evento {
  final String compradorCurp;
  final String vendedorCurp;

  CompraventaEvento({
    required super.id,
    required super.bovinoId,
    required super.fecha,
    super.observaciones,
    required this.compradorCurp,
    required this.vendedorCurp,
  });

  factory CompraventaEvento.fromJson(Map<String, dynamic> json) {
    return CompraventaEvento(
      id: json['id'],
      bovinoId: json['bovino_id'],
      fecha: DateTime.parse(json['fecha']),
      observaciones: json['observaciones'],
      compradorCurp: json['comprador_curp'],
      vendedorCurp: json['vendedor_curp'],
    );
  }
}

// Traslado event
class TrasladoEvento extends Evento {
  final String predioNuevoId;

  TrasladoEvento({
    required super.id,
    required super.bovinoId,
    required super.fecha,
    super.observaciones,
    required this.predioNuevoId,
  });

  factory TrasladoEvento.fromJson(Map<String, dynamic> json) {
    return TrasladoEvento(
      id: json['id'],
      bovinoId: json['bovino_id'],
      fecha: DateTime.parse(json['fecha']),
      observaciones: json['observaciones'],
      predioNuevoId: json['predio_nuevo_id'],
    );
  }
}

// Enfermedad event
class EnfermedadEvento extends Evento {
  final String? enfermedadId; // enf.id returned as 'enfermedad_id' in response
  final String veterinarioId;
  final String tipo;

  EnfermedadEvento({
    required super.id,
    required super.bovinoId,
    required super.fecha,
    super.observaciones,
    this.enfermedadId,
    required this.veterinarioId,
    required this.tipo,
  });

  factory EnfermedadEvento.fromJson(Map<String, dynamic> json) {
    return EnfermedadEvento(
      id: json['id'],
      bovinoId: json['bovino_id'],
      fecha: DateTime.parse(json['fecha']),
      observaciones: json['observaciones'],
      enfermedadId: json['enfermedad_id'],
      veterinarioId: json['veterinario_id'],
      tipo: json['tipo'],
    );
  }
}

// Tratamiento event
class TratamientoEvento extends Evento {
  final String? enfermedadId;
  final String veterinarioId;
  final String medicamento;
  final String dosis;
  final String periodo;

  TratamientoEvento({
    required super.id,
    required super.bovinoId,
    required super.fecha,
    super.observaciones,
    this.enfermedadId,
    required this.veterinarioId,
    required this.medicamento,
    required this.dosis,
    required this.periodo,
  });

  factory TratamientoEvento.fromJson(Map<String, dynamic> json) {
    return TratamientoEvento(
      id: json['id'],
      bovinoId: json['bovino_id'],
      fecha: DateTime.parse(json['fecha']),
      observaciones: json['observaciones'],
      enfermedadId: json['enfermedad_id'],
      veterinarioId: json['veterinario_id'],
      medicamento: json['medicamento'],
      dosis: json['dosis'],
      periodo: json['periodo'],
    );
  }
}

enum EventType {
  peso,
  dieta,
  vacunacion,
  desparasitacion,
  laboratorio,
  compraventa,
  traslado,
  enfermedad,
  tratamiento,
}

extension EventTypeExtension on EventType {
  String get value {
    switch (this) {
      case EventType.peso:
        return 'pesos';
      case EventType.dieta:
        return 'dietas';
      case EventType.vacunacion:
        return 'vacunaciones';
      case EventType.desparasitacion:
        return 'desparasitaciones';
      case EventType.laboratorio:
        return 'laboratorios';
      case EventType.compraventa:
        return 'compraventas';
      case EventType.traslado:
        return 'traslados';
      case EventType.enfermedad:
        return 'enfermedades';
      case EventType.tratamiento:
        return 'tratamientos';
    }
  }

  String get displayName {
    switch (this) {
      case EventType.peso:
        return 'Registro de Peso';
      case EventType.dieta:
        return 'Cambio de Dieta';
      case EventType.vacunacion:
        return 'Vacunación';
      case EventType.desparasitacion:
        return 'Desparasitación';
      case EventType.laboratorio:
        return 'Análisis de Laboratorio';
      case EventType.compraventa:
        return 'Compra/Venta';
      case EventType.traslado:
        return 'Traslado';
      case EventType.enfermedad:
        return 'Detección de Enfermedad';
      case EventType.tratamiento:
        return 'Tratamiento';
    }
  }
}
