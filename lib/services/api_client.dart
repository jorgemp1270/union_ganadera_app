import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String defaultBaseUrl = 'http://10.0.2.2:8000';

  final Dio dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  ApiClient()
    : dio = Dio(
        BaseOptions(
          baseUrl: defaultBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      ) {
    _setupInterceptors();
    _loadCustomBaseUrl();
  }

  Future<void> _loadCustomBaseUrl() async {
    try {
      final savedIp = await storage.read(key: 'api_ip');
      final savedPort = await storage.read(key: 'api_port');

      if (savedIp != null && savedPort != null) {
        dio.options.baseUrl = 'http://$savedIp:$savedPort';
      }
    } catch (e) {
      // Use default URL if there's an error
    }
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token to requests
          final token = await storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired, clear storage
            await storage.delete(key: 'access_token');
            // Navigation will be handled by the UI
          }
          return handler.next(error);
        },
      ),
    );

    // Logging interceptor for debugging
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: true,
        responseHeader: false,
      ),
    );
  }

  Future<void> saveToken(String token) async {
    await storage.write(key: 'access_token', value: token);
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'access_token');
  }

  Future<void> clearToken() async {
    await storage.delete(key: 'access_token');
  }
}
