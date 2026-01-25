import 'package:dio/dio.dart';
import 'package:union_ganadera_app/models/predio.dart';
import 'package:union_ganadera_app/services/api_client.dart';

class PredioService {
  final ApiClient apiClient;

  PredioService(this.apiClient);

  Future<List<Predio>> getPredios({
    int skip = 0,
    int limit = 100,
    String? domicilioId,
  }) async {
    try {
      final params = <String, dynamic>{'skip': skip, 'limit': limit};
      if (domicilioId != null) {
        params['domicilio_id'] = domicilioId;
      }

      final response = await apiClient.dio.get(
        '/predios/',
        queryParameters: params,
      );
      return (response.data as List)
          .map((json) => Predio.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception('Error al obtener predios: ${e.message}');
    }
  }

  Future<Predio> getPredio(String id) async {
    try {
      final response = await apiClient.dio.get('/predios/$id');
      return Predio.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Predio no encontrado');
      }
      throw Exception('Error al obtener predio: ${e.message}');
    }
  }

  Future<Predio> createPredio(Predio predio) async {
    try {
      final response = await apiClient.dio.post(
        '/predios/',
        data: predio.toJson(),
      );
      return Predio.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al crear predio: ${e.message}');
    }
  }

  Future<Predio> updatePredio(String id, Map<String, dynamic> updates) async {
    try {
      final response = await apiClient.dio.put('/predios/$id', data: updates);
      return Predio.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('No autorizado para actualizar este predio');
      }
      throw Exception('Error al actualizar predio: ${e.message}');
    }
  }

  Future<void> deletePredio(String id) async {
    try {
      await apiClient.dio.delete('/predios/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Predio no encontrado');
      }
      throw Exception('Error al eliminar predio: ${e.message}');
    }
  }
}
