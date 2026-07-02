// Fichier : lib/data/providers/bagagiste_provider.dart

import 'package:flutter/material.dart';
import '../services/bagagiste_service.dart';

class BagagisteProvider extends ChangeNotifier {
  final BagagisteService _service = BagagisteService();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic> _stats = {
    'enregistres_aujourd_hui': 0,
    'en_transit': 0,
    'arrives_aujourd_hui': 0,
    'recuperes_aujourd_hui': 0,
    'perdus': 0,
    'total_aujourd_hui': 0,
  };
  List<Map<String, dynamic>> _bagages = [];
  List<Map<String, dynamic>> _signalements = [];
  Map<String, dynamic>? _reservationTrouvee;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get stats => _stats;
  List<Map<String, dynamic>> get bagages => _bagages;
  List<Map<String, dynamic>> get signalements => _signalements;
  Map<String, dynamic>? get reservationTrouvee => _reservationTrouvee;

  Future<void> chargerStats() async {
    try {
      _stats = await _service.getStats();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> chargerBagages({String? statut}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _bagages = await _service.listeBagages(statut: statut);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> chargerSignalements({String? statut}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _signalements = await _service.listeSignalements(statut: statut);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> chercherReservation(String codeQr) async {
    _isLoading = true;
    _errorMessage = null;
    _reservationTrouvee = null;
    notifyListeners();
    try {
      final result = await _service.chercherReservation(codeQr);
      _reservationTrouvee = result['reservation'] != null
          ? Map<String, dynamic>.from(result['reservation'] as Map)
          : null;
      _isLoading = false;
      notifyListeners();
      return _reservationTrouvee != null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearReservationTrouvee() {
    _reservationTrouvee = null;
    notifyListeners();
  }

  Future<bool> enregistrerBagage({
    required int reservationId,
    required double poids,
    String description = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.enregistrerBagage(
        reservationId: reservationId,
        poids: poids,
        description: description,
      );
      await chargerStats();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatutBagage(int id, String statut) async {
    try {
      await _service.updateStatut(id, statut);
      final index = _bagages.indexWhere((b) => b['id'] == id);
      if (index != -1) {
        _bagages[index] = {..._bagages[index], 'statut': statut};
      }
      await chargerStats();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> prendreEnCharge(int signalementId) async {
    try {
      await _service.prendreEnCharge(signalementId);
      await chargerSignalements();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> marquerRetrouve(int signalementId) async {
    try {
      await _service.marquerRetrouve(signalementId);
      await chargerSignalements();
      await chargerStats();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmerPerteDefinitive(int signalementId) async {
    try {
      await _service.confirmerPerteDefinitive(signalementId);
      await chargerSignalements();
      await chargerStats();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}