// Fichier : lib/data/services/bagagiste_service.dart

import 'package:dio/dio.dart';
import 'api_service.dart';

class BagagisteService {
  final ApiService _api = ApiService();

  // ── Enregistrer un bagage
  Future<Map<String, dynamic>> enregistrerBagage({
    required int reservationId,
    required double poids,
    String description = '',
  }) async {
    try {
      final res = await _api.post('/bagagiste/bagages', {
        'reservation_id': reservationId,
        'poids': poids,
        'description': description,
      });
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? e.response?.data['message'] ?? 'Erreur enregistrement'
          : 'Erreur enregistrement';
      throw Exception(msg);
    }
  }

  // ── Liste des bagages du jour
  Future<List<Map<String, dynamic>>> listeBagages({String? statut}) async {
    try {
      final params =
      statut != null && statut != 'tous' ? '?statut=$statut' : '';
      final res = await _api.get('/bagagiste/bagages$params');
      final data = res.data;
      if (data is List) {
        return data
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['message'] ?? 'Erreur chargement bagages');
    }
  }

  // ── Mettre à jour le statut d'un bagage
  Future<Map<String, dynamic>> updateStatut(int id, String statut) async {
    try {
      final res = await _api.put('/bagagiste/bagages/$id/statut', {
        'statut': statut,
      });
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['message'] ?? 'Erreur mise à jour statut');
    }
  }

  // ── Chercher une réservation par QR
  Future<Map<String, dynamic>> chercherReservation(String codeQr) async {
    try {
      final res = await _api.post('/bagagiste/chercher-reservation', {
        'code_qr': codeQr,
      });
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['message'] ?? 'Réservation introuvable');
    }
  }

  // ── Stats du jour
  Future<Map<String, dynamic>> getStats() async {
    try {
      final res = await _api.get('/bagagiste/stats');
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (_) {
      return {
        'enregistres_aujourd_hui': 0,
        'en_transit': 0,
        'arrives_aujourd_hui': 0,
        'recuperes_aujourd_hui': 0,
        'perdus': 0,
        'total_aujourd_hui': 0,
      };
    }
  }

  // ── Liste des signalements
  Future<List<Map<String, dynamic>>> listeSignalements(
      {String? statut}) async {
    try {
      final params =
      statut != null && statut != 'tous' ? '?statut=$statut' : '';
      final res = await _api.get('/bagagiste/signalements$params');
      final data = res.data;
      if (data is List) {
        return data
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['message'] ?? 'Erreur chargement signalements');
    }
  }

  // ── Prendre en charge un signalement
  Future<void> prendreEnCharge(int signalementId) async {
    try {
      await _api.put(
          '/bagagiste/signalements/$signalementId/statut', {'statut': 'en_cours'});
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['message'] ?? 'Erreur prise en charge');
    }
  }

  // ── Marquer retrouvé
  Future<void> marquerRetrouve(int signalementId) async {
    try {
      await _api.put(
          '/bagagiste/signalements/$signalementId/statut', {'statut': 'resolu'});
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Erreur mise à jour');
    }
  }

  // ── Confirmer perte définitive
  Future<void> confirmerPerteDefinitive(int signalementId) async {
    try {
      await _api.put(
          '/bagagiste/signalements/$signalementId/confirmer-perdu', {});
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['message'] ?? 'Erreur confirmation perte');
    }
  }
}