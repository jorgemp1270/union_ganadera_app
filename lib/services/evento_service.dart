import 'package:dio/dio.dart';
import 'package:union_ganadera_app/models/evento.dart';
import 'package:union_ganadera_app/services/api_client.dart';

class EventoService {
  final ApiClient apiClient;

  EventoService(this.apiClient);

  Future<List<Evento>> getEventos({int skip = 0, int limit = 100}) async {
    try {
      final response = await apiClient.dio.get(
        '/eventos/',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      return (response.data as List)
          .map((json) => Evento.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception('Error al obtener eventos: ${e.message}');
    }
  }

  Future<List<Evento>> getEventosByBovino(
    String bovinoId, {
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await apiClient.dio.get(
        '/eventos/bovino/$bovinoId',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      return (response.data as List)
          .map((json) => Evento.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception('Error al obtener eventos: ${e.message}');
    }
  }

  // Generic method to get events by type
  Future<List<T>> getEventosByType<T extends Evento>(
    EventType eventType,
    String bovinoId, {
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await apiClient.dio.get(
        '/eventos/${eventType.value}/bovino/$bovinoId',
        queryParameters: {'skip': skip, 'limit': limit},
      );

      return (response.data as List).map((json) {
        switch (eventType) {
          case EventType.peso:
            return PesoEvento.fromJson(json) as T;
          case EventType.dieta:
            return DietaEvento.fromJson(json) as T;
          case EventType.vacunacion:
            return VacunacionEvento.fromJson(json) as T;
          case EventType.desparasitacion:
            return DesparasitacionEvento.fromJson(json) as T;
          case EventType.laboratorio:
            return LaboratorioEvento.fromJson(json) as T;
          case EventType.compraventa:
            return CompraventaEvento.fromJson(json) as T;
          case EventType.traslado:
            return TrasladoEvento.fromJson(json) as T;
          case EventType.enfermedad:
            return EnfermedadEvento.fromJson(json) as T;
          case EventType.tratamiento:
            return TratamientoEvento.fromJson(json) as T;
          case EventType.remision:
            return RemisionEvento.fromJson(json) as T;
        }
      }).toList();
    } on DioException catch (e) {
      throw Exception('Error al obtener eventos: ${e.message}');
    }
  }

  Future<Evento> createPesoEvent({
    required String bovinoId,
    required double pesoNuevo,
    String? observaciones,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/eventos/',
        data: {
          'type': 'peso',
          'data': {
            'bovino_id': bovinoId,
            'peso_nuevo': pesoNuevo,
            'observaciones': observaciones ?? '',
          },
        },
      );
      return Evento.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al crear evento: ${e.message}');
    }
  }

  Future<Evento> createVacunacionEvent({
    required String bovinoId,
    required String veterinarioId,
    required String tipo,
    required String lote,
    required String laboratorio,
    required DateTime fechaProx,
    String? observaciones,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/eventos/',
        data: {
          'type': 'vacunacion',
          'data': {
            'bovino_id': bovinoId,
            'veterinario_id': veterinarioId,
            'tipo': tipo,
            'lote': lote,
            'laboratorio': laboratorio,
            'fecha_prox': fechaProx.toIso8601String().split('T')[0],
            'observaciones': observaciones ?? '',
          },
        },
      );
      return Evento.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al crear evento: ${e.message}');
    }
  }

  Future<Evento> createDietaEvent({
    required String bovinoId,
    required String alimento,
    String? observaciones,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/eventos/',
        data: {
          'type': 'dieta',
          'data': {
            'bovino_id': bovinoId,
            'alimento': alimento,
            'observaciones': observaciones ?? '',
          },
        },
      );
      return Evento.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al crear evento: ${e.message}');
    }
  }

  Future<Evento> createDesparasitacionEvent({
    required String bovinoId,
    required String veterinarioId,
    required String medicamento,
    required String dosis,
    required DateTime fechaProx,
    String? observaciones,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/eventos/',
        data: {
          'type': 'desparasitacion',
          'data': {
            'bovino_id': bovinoId,
            'veterinario_id': veterinarioId,
            'medicamento': medicamento,
            'dosis': dosis,
            'fecha_prox': fechaProx.toIso8601String().split('T')[0],
            'observaciones': observaciones ?? '',
          },
        },
      );
      return Evento.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al crear evento: ${e.message}');
    }
  }

  Future<Evento> createLaboratorioEvent({
    required String bovinoId,
    required String veterinarioId,
    required String tipo,
    required String resultado,
    String? observaciones,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/eventos/',
        data: {
          'type': 'laboratorio',
          'data': {
            'bovino_id': bovinoId,
            'veterinario_id': veterinarioId,
            'tipo': tipo,
            'resultado': resultado,
            'observaciones': observaciones ?? '',
          },
        },
      );
      return Evento.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al crear evento: ${e.message}');
    }
  }

  Future<Evento> createCompraventaEvent({
    required String bovinoId,
    required String compradorCurp,
    required String vendedorCurp,
    String? observaciones,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/eventos/',
        data: {
          'type': 'compraventa',
          'data': {
            'bovino_id': bovinoId,
            'comprador_curp': compradorCurp,
            'vendedor_curp': vendedorCurp,
            'observaciones': observaciones ?? '',
          },
        },
      );
      return Evento.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al crear evento: ${e.message}');
    }
  }

  Future<Evento> createTrasladoEvent({
    required String bovinoId,
    required String predioNuevoId,
    String? observaciones,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/eventos/',
        data: {
          'type': 'traslado',
          'data': {
            'bovino_id': bovinoId,
            'predio_nuevo_id': predioNuevoId,
            'observaciones': observaciones ?? '',
          },
        },
      );
      return Evento.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al crear evento: ${e.message}');
    }
  }

  Future<Evento> createEnfermedadEvent({
    required String bovinoId,
    required String veterinarioId,
    required String tipo,
    String? observaciones,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/eventos/',
        data: {
          'type': 'enfermedad',
          'data': {
            'bovino_id': bovinoId,
            'veterinario_id': veterinarioId,
            'tipo': tipo,
            'observaciones': observaciones ?? '',
          },
        },
      );
      return Evento.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al crear evento: ${e.message}');
    }
  }

  Future<Evento> createTratamientoEvent({
    required String bovinoId,
    String? enfermedadId,
    required String veterinarioId,
    required String medicamento,
    required String dosis,
    required String periodo,
    String? observaciones,
  }) async {
    try {
      final data = <String, dynamic>{
        'bovino_id': bovinoId,
        'veterinario_id': veterinarioId,
        'medicamento': medicamento,
        'dosis': dosis,
        'periodo': periodo,
        'observaciones': observaciones ?? '',
      };
      if (enfermedadId != null) data['enfermedad_id'] = enfermedadId;
      final response = await apiClient.dio.post(
        '/eventos/',
        data: {'type': 'tratamiento', 'data': data},
      );
      return Evento.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al crear evento: ${e.message}');
    }
  }

  Future<Evento> createRemisionEvent({
    required String bovinoId,
    required String enfermedadId,
    String? observaciones,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/eventos/',
        data: {
          'type': 'remision',
          'data': {
            'bovino_id': bovinoId,
            'enfermedad_id': enfermedadId,
            'observaciones': observaciones ?? '',
          },
        },
      );
      return Evento.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al crear evento: ${e.message}');
    }
  }
}
