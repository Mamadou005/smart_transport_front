import 'api_service.dart';

class AgentService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> scanner(String code) async {
    print('SCANNING CODE: $code');
    try {
      final response = await _api.post('/agent/scanner', {'code': code});
      print('SCAN RESULT: ${response.data}');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      print('SCAN ERROR: $e');
      return {
        'type':    'inconnu',
        'valide':  false,
        'code':    code,
        'message': 'Code non reconnu',
      };
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    final response = await _api.get('/agent/stats');
    return Map<String, dynamic>.from(response.data);
  }

  Future<List<dynamic>> getReservationsDuJour({String? date}) async {
    final dateParam = date ?? DateTime.now().toIso8601String().substring(0, 10);
    final response = await _api.get(
        '/agent/reservations-du-jour?date=$dateParam');
    return response.data as List;
  }

  Future<Map<String, dynamic>> enregistrerBagage({
    required int reservationId,
    required double poids,
    String? description,
  }) async {
    final response = await _api.post('/agent/bagages', {
      'reservation_id': reservationId,
      'poids':          poids,
      'description':    description ?? 'Bagage',
    });
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> updateStatutBagage(int id, String statut) async {
    await _api.put('/agent/bagages/$id/statut', {'statut': statut});
  }
}