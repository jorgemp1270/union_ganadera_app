import 'dart:io';
import 'package:dio/dio.dart';
import 'package:union_ganadera_app/models/document_file.dart';
import 'package:union_ganadera_app/models/domicilio.dart';
import 'package:union_ganadera_app/services/api_client.dart';

class DomicilioService {
  final ApiClient apiClient;

  DomicilioService(this.apiClient);

  Future<List<Domicilio>> getDomicilios({int skip = 0, int limit = 100}) async {
    try {
      final response = await apiClient.dio.get(
        '/domicilios/',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      return (response.data as List)
          .map((json) => Domicilio.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception('Error al obtener domicilios: ${e.message}');
    }
  }

  Future<Domicilio> getDomicilio(String id) async {
    try {
      final response = await apiClient.dio.get('/domicilios/$id');
      return Domicilio.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al obtener domicilio: ${e.message}');
    }
  }

  Future<Domicilio> createDomicilio(Domicilio domicilio) async {
    try {
      final response = await apiClient.dio.post(
        '/domicilios/',
        data: domicilio.toJson(),
      );
      return Domicilio.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al crear domicilio: ${e.message}');
    }
  }

  Future<Domicilio> updateDomicilio(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await apiClient.dio.put(
        '/domicilios/$id',
        data: updates,
      );
      return Domicilio.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('No autorizado para actualizar este domicilio');
      }
      throw Exception('Error al actualizar domicilio: ${e.message}');
    }
  }

  Future<void> deleteDomicilio(String id) async {
    try {
      await apiClient.dio.delete('/domicilios/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Domicilio no encontrado');
      }
      throw Exception('Error al eliminar domicilio: ${e.message}');
    }
  }

  /// Uploads a proof-of-address document linked to a specific domicilio.
  /// Storage key: {user_id}/comprobante_domicilio/{domicilio_id}/{uuid}.{ext}
  Future<DocumentFile> uploadDocument({
    required String domicilioId,
    required File file,
  }) async {
    try {
      final fileName = file.path.split(RegExp(r'[/\\]')).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });
      final response = await apiClient.dio.post(
        '/domicilios/$domicilioId/upload-document',
        data: formData,
      );
      return DocumentFile.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('No autorizado para subir documentos a este domicilio');
      }
      throw Exception('Error al subir comprobante: ${e.message}');
    }
  }
}
