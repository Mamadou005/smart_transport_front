import '../services/api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _api.post('/login', {
      'email':    email,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> register({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String password,
  }) async {
    final response = await _api.post('/register', {
      'nom':       nom,
      'prenom':    prenom,
      'email':     email,
      'telephone': telephone,
      'password':  password,
      'role':      'passager',
    });
    return response.data;
  }
}