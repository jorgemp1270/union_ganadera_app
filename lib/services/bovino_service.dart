import 'package:dio/dio.dart';
import 'package:union_ganadera_app/models/bovino.dart';
import 'package:union_ganadera_app/services/api_client.dart';

class BovinoService {
  final ApiClient apiClient;

  BovinoService(this.apiClient);

  Future<List<Bovino>> getBovinos({int skip = 0, int limit = 100}) async {
    try {
      final response = await apiClient.dio.get(
        '/bovinos/',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      return (response.data as List)
          .map((json) => Bovino.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception('Error al obtener bovinos: ${e.message}');
    }
  }

  Future<Bovino> getBovino(String id) async {
    try {
      final response = await apiClient.dio.get('/bovinos/$id');
      return Bovino.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Bovino no encontrado');
      }
      throw Exception('Error al obtener bovino: ${e.message}');
    }
  }

  Future<Bovino> createBovino(Bovino bovino) async {
    try {
      final response = await apiClient.dio.post(
        '/bovinos/',
        data: bovino.toJson(),
      );
      return Bovino.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al crear bovino: ${e.message}');
    }
  }

  Future<Bovino> updateBovino(String id, Map<String, dynamic> updates) async {
    try {
      final response = await apiClient.dio.put('/bovinos/$id', data: updates);
      return Bovino.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('No autorizado para actualizar este bovino');
      }
      throw Exception('Error al actualizar bovino: ${e.message}');
    }
  }

  Future<void> deleteBovino(String id) async {
    try {
      await apiClient.dio.delete('/bovinos/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Bovino no encontrado');
      }
      throw Exception('Error al eliminar bovino: ${e.message}');
    }
  }
}
