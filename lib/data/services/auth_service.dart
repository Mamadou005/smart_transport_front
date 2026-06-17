import 'package:dio/dio.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  // ✅ POST /api/login
  Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final response = await _api.post('/login', {
        'email':    email,
        'password': password,
      });
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message']
          ?? 'Erreur de connexion';
      throw Exception(msg);
    }
  }

  // ✅ POST /api/register
  Future<Map<String, dynamic>> register({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String password,
  }) async {
    try {
      final response = await _api.post('/register', {
        'nom':      nom,
        'prenom':   prenom,
        'email':    email,
        'telephone': telephone,
        'password': password,
        'role':     'passager',
      });
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message']
          ?? 'Erreur d\'inscription';
      throw Exception(msg);
    }
  }

  // ✅ GET /api/me
  Future<Map<String, dynamic>> me() async {
    try {
      final response = await _api.get('/me');
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message']
          ?? 'Erreur de récupération du profil';
      throw Exception(msg);
    }
  }

  // ✅ POST /api/logout
  Future<void> logout() async {
    try {
      await _api.post('/logout', {});
    } catch (_) {}
  }
}