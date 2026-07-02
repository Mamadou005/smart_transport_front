// Fichier : lib/data/services/agent_service.dart
// Agent Terminal UNIQUEMENT : scanner, embarquement, réservations, stats

import 'package:dio/dio.dart';
import 'api_service.dart';

class AgentService {
  final ApiService _api = ApiService();

  // ── Scanner un QR Code (réservation uniquement)
  Future<Map<String, dynamic>> scanner(String codeQr) async {
    try {
      final res = await _api.post('/agent/scanner', {'code_qr': codeQr});
      final data = res.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'valide': false, 'message': 'Réponse invalide'};
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? e.response?.data['message'] ?? 'Code invalide'
          : 'Code invalide';
      return {'valide': false, 'message': msg};
    }
  }

  // ── Réservations du jour (filtrées par date)
  Future<List<Map<String, dynamic>>> getReservationsDuJour({
    String? date,
  }) async {
    try {
      final param = date != null ? '?date=$date' : '';
      final res = await _api.get('/agent/reservations-du-jour$param');
      final data = res.data;
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['message'] ?? 'Erreur chargement réservations');
    }
  }

  // ── Stats du jour (réservations + embarqués)
  Future<Map<String, dynamic>> getStats() async {
    try {
      final res = await _api.get('/agent/stats');
      final data = res.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {};
    } on DioException catch (_) {
      return {
        'reservations_aujourd_hui': 0,
        'embarques_aujourd_hui': 0,
        'en_attente': 0,
        'confirmees': 0,
      };
    }
  }
}