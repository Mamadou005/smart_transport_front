import 'api_service.dart';

class AdminService {
  final ApiService _api = ApiService();

  // Stats
  Future<Map<String, dynamic>> getStats() async {
    final response = await _api.get('/admin/stats');
    return Map<String, dynamic>.from(response.data);
  }

  // Utilisateurs
  Future<List<dynamic>> getUtilisateurs({String? role, String? search}) async {
    String url = '/admin/utilisateurs';
    final params = <String>[];
    if (role != null)   params.add('role=$role');
    if (search != null) params.add('search=$search');
    if (params.isNotEmpty) url += '?${params.join('&')}';
    final response = await _api.get(url);
    return response.data as List;
  }

  Future<void> creerUtilisateur(Map<String, dynamic> data) async {
    await _api.post('/admin/utilisateurs', data);
  }

  Future<void> supprimerUtilisateur(int id) async {
    await _api.delete('/admin/utilisateurs/$id');
  }

  // Voyages
  Future<List<dynamic>> getVoyages() async {
    final response = await _api.get('/admin/voyages');
    return response.data as List;
  }

  Future<void> creerVoyage(Map<String, dynamic> data) async {
    await _api.post('/admin/voyages', data);
  }

  Future<void> supprimerVoyage(int id) async {
    await _api.delete('/admin/voyages/$id');
  }

  // Signalements
  Future<List<dynamic>> getSignalements() async {
    final response = await _api.get('/admin/signalements');
    return response.data as List;
  }

  Future<void> updateSignalement(int id, String statut) async {
    await _api.put('/admin/signalements/$id/statut', {'statut': statut});
  }

  Future<void> updateVoyage(int id, Map<String, dynamic> data) async {
    await _api.put('/admin/voyages/$id', data);
  }

  Future<void> confirmerBagagePerdu(int signalementId) async {
    await _api.put(
        '/admin/signalements/$signalementId/confirmer-perdu', {});
  }
}