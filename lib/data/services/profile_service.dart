import 'api_service.dart';

class ProfileService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getProfil() async {
    final response = await _api.get('/profile');
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> updateProfil({
    required String nom,
    required String prenom,
    required String telephone,
    required String email,
  }) async {
    final response = await _api.put('/profile', {
      'nom':       nom,
      'prenom':    prenom,
      'telephone': telephone,
      'email':     email,
    });
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> changerMotDePasse({
    required String ancienPassword,
    required String nouveauPassword,
  }) async {
    await _api.post('/profile/password', {
      'ancien_password':              ancienPassword,
      'nouveau_password':             nouveauPassword,
      'nouveau_password_confirmation': nouveauPassword,
    });
  }

  Future<void> supprimerCompte(String password) async {
    await _api.delete('/profile');
  }
}