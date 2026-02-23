import 'dart:io';
import 'package:dio/dio.dart';
import 'package:union_ganadera_app/models/bovino.dart';
import 'package:union_ganadera_app/services/api_client.dart';

class BovinoService {
  final ApiClient apiClient;

  BovinoService(this.apiClient);

  Future<List<Bovino>> getBovinos({
    int skip = 0,
    int limit = 100,
    String? predioId,
  }) async {
    try {
      final params = <String, dynamic>{'skip': skip, 'limit': limit};
      if (predioId != null) params['predio_id'] = predioId;
      final response = await apiClient.dio.get(
        '/bovinos/',
        queryParameters: params,
      );
      return (response.data as List)
          .map((json) => Bovino.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception('Error al obtener bovinos: ${e.message}');
    }
  }

  Future<List<Bovino>> getBovinosByPredio(
    String predioId, {
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await apiClient.dio.get(
        '/predios/$predioId/bovinos',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      return (response.data as List)
          .map((json) => Bovino.fromJson(json))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('No autorizado para ver el ganado de este predio');
      }
      throw Exception('Error al obtener ganado del predio: ${e.message}');
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

  Future<Bovino> uploadNosePhoto(String bovinoId, File imageFile) async {
    try {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await apiClient.dio.post(
        '/bovinos/$bovinoId/upload-nose-photo',
        data: formData,
      );
      return Bovino.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('No autorizado para subir foto para este bovino');
      }
      throw Exception('Error al subir foto de nariz: ${e.message}');
    }
  }

  /// Search for cattle by barcode, RFID, or nose photo key (veterinarians only)
  Future<Bovino> searchBovino({
    String? areteBarcode,
    String? areteRfid,
    String? narizStorageKey,
  }) async {
    try {
      if (areteBarcode == null &&
          areteRfid == null &&
          narizStorageKey == null) {
        throw Exception('Debe proporcionar al menos un parámetro de búsqueda');
      }

      final queryParams = <String, String>{};
      if (areteBarcode != null) queryParams['arete_barcode'] = areteBarcode;
      if (areteRfid != null) queryParams['arete_rfid'] = areteRfid;
      if (narizStorageKey != null) {
        queryParams['nariz_storage_key'] = narizStorageKey;
      }

      final response = await apiClient.dio.get(
        '/bovinos/search',
        queryParameters: queryParams,
      );
      return Bovino.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('No se proporcionó ningún parámetro de búsqueda');
      }
      if (e.response?.statusCode == 403) {
        throw Exception('Solo veterinarios pueden buscar ganado');
      }
      if (e.response?.statusCode == 404) {
        throw Exception(
          'No se encontró el bovino con los datos proporcionados',
        );
      }
      throw Exception('Error al buscar bovino: ${e.message}');
    }
  }
}
