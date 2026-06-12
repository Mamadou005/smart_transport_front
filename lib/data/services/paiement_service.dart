import 'api_service.dart';

class PaiementService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> initierPaiement({
    required int    reservationId,
    required String methode,
    required String telephone,
  }) async {
    final response = await _api.post('/paiements/initier', {
      'reservation_id':     reservationId,
      'methode':            methode,
      'telephone_paiement': telephone,
    });
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> confirmerPaiement(
      String reference) async {
    final response = await _api.post(
        '/paiements/$reference/confirmer', {});
    return Map<String, dynamic>.from(response.data);
  }

  Future<List<dynamic>> getHistorique() async {
    final response = await _api.get('/paiements/historique');
    return response.data as List;
  }
}