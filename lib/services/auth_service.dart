import 'package:dio/dio.dart';
import 'package:union_ganadera_app/models/user.dart';
import 'package:union_ganadera_app/services/api_client.dart';

class AuthService {
  final ApiClient apiClient;

  AuthService(this.apiClient);

  Future<String> login(String curp, String password) async {
    try {
      final response = await apiClient.dio.post(
        '/login',
        data: {'curp': curp, 'contrasena': password},
      );

      final token = response.data['access_token'];
      await apiClient.saveToken(token);
      return token;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('CURP o contraseña incorrectos');
      }
      throw Exception('Error de conexión: ${e.message}');
    }
  }

  Future<User> signup(UserRegistration registration) async {
    try {
      final response = await apiClient.dio.post(
        '/signup',
        data: registration.toJson(),
      );

      return User.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        throw Exception('Datos de registro inválidos');
      }
      throw Exception('Error al registrar: ${e.message}');
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await apiClient.dio.get('/users/me');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al obtener usuario: ${e.message}');
    }
  }

  Future<void> logout() async {
    await apiClient.clearToken();
  }
}
