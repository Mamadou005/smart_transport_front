import 'package:flutter/material.dart';
import '../models/bagage_model.dart';
import '../models/reservation_model.dart';
import '../services/bagage_service.dart';
import '../services/reservation_service.dart';

class BagageProvider extends ChangeNotifier {
  final BagageService      _bagageService      = BagageService();
  final ReservationService _reservationService = ReservationService();

  List<BagageModel>      _bagages      = [];
  List<ReservationModel> _reservations = [];
  BagageModel?           _bagageDetail;
  bool    _isLoading    = false;
  String? _errorMessage;

  List<BagageModel>      get bagages      => _bagages;
  List<ReservationModel> get reservations => _reservations;
  BagageModel?           get bagageDetail => _bagageDetail;
  bool    get isLoading    => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> chargerMesBagages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _bagages = await _bagageService.getMesBagages();
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> chargerReservations() async {
    try {
      _reservations = await _reservationService.getMesReservations();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<BagageModel?> enregistrerBagage({
    required int reservationId,
    required double poids,
    String? description,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final bagage = await _bagageService.enregistrerBagage(
        reservationId: reservationId,
        poids:         poids,
        description:   description,
      );
      _bagages.insert(0, bagage);
      _isLoading = false;
      notifyListeners();
      return bagage;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> chargerDetail(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _bagageDetail = await _bagageService.getBagageDetail(id);
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}