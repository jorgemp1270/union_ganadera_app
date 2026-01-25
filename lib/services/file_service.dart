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
      String fileName = file.path.split('/').last;

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'doc_type': docType.value,
      });

      final response = await apiClient.dio.post(
        '/files/upload',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      return DocumentFile.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al subir archivo: ${e.message}');
    }
  }
}
