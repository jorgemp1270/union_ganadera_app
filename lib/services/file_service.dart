import 'dart:io';
import 'package:dio/dio.dart';
import 'package:union_ganadera_app/models/document_file.dart';
import 'package:union_ganadera_app/services/api_client.dart';

class FileService {
  final ApiClient apiClient;

  FileService(this.apiClient);

  Future<List<DocumentFile>> getFiles({int skip = 0, int limit = 100}) async {
    try {
      final response = await apiClient.dio.get(
        '/files/',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      return (response.data as List)
          .map((json) => DocumentFile.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception('Error al obtener documentos: ${e.message}');
    }
  }

  Future<DocumentFile> uploadFile({
    required File file,
    required DocType docType,
  }) async {
    try {
      String fileName = file.path.split(RegExp(r'[/\\]')).last;

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'doc_type': docType.value,
      });

      final response = await apiClient.dio.post(
        '/files/upload',
        data: formData,
      );

      return DocumentFile.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al subir archivo: ${e.message}');
    }
  }

  Future<DocumentFile> deleteFile(String docId) async {
    try {
      final response = await apiClient.dio.delete('/files/$docId');
      return DocumentFile.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('No autorizado para eliminar este documento');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Documento no encontrado');
      }
      throw Exception('Error al eliminar documento: ${e.message}');
    }
  }

  /// Uploads a document linked to a specific predio.
  /// Storage key: {user_id}/predio/{predio_id}/{uuid}.{ext}
  Future<DocumentFile> uploadPredioDocument({
    required String predioId,
    required File file,
  }) async {
    try {
      final fileName = file.path.split(RegExp(r'[/\\]')).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });
      final response = await apiClient.dio.post(
        '/predios/$predioId/upload-document',
        data: formData,
      );
      return DocumentFile.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('No autorizado para subir documentos a este predio');
      }
      throw Exception('Error al subir comprobante de predio: ${e.message}');
    }
  }
}
