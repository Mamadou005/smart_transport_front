import 'package:flutter/material.dart';
import '../models/voyage_model.dart';
import '../models/reservation_model.dart';
import '../services/voyage_service.dart';
import '../services/reservation_service.dart';
import '../services/dashboard_service.dart';

class ReservationProvider extends ChangeNotifier {
  final VoyageService      _voyageService      = VoyageService();
  final ReservationService _reservationService = ReservationService();
  final DashboardService   _dashboardService   = DashboardService();

  List<VoyageModel>      _voyages      = [];
  List<ReservationModel> _reservations = [];
  Map<String, dynamic>   _stats        = {};
  bool    _isLoading    = false;
  String? _errorMessage;

  List<VoyageModel>      get voyages      => _voyages;
  List<ReservationModel> get reservations => _reservations;
  Map<String, dynamic>   get stats        => _stats;
  bool    get isLoading    => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> chargerVoyages({
    String? origine,
    String? destination,
    String? date,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _voyages = await _voyageService.getVoyages(
        origine:     origine,
        destination: destination,
        date:        date,
      );
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> chargerMesReservations() async {
    _isLoading = true;
    notifyListeners();
    try {
      _reservations = await _reservationService.getMesReservations();
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> chargerStats() async {
    try {
      _stats = await _dashboardService.getStatistiquesPassager();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<ReservationModel?> creerReservation(int voyageId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await _reservationService.creerReservation(voyageId);
      _reservations.insert(0, res);
      _isLoading = false;
      notifyListeners();
      return res;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> annulerReservation(int id) async {
    try {
      await _reservationService.annulerReservation(id);
      // ✅ Recharge la liste complète
      await chargerMesReservations();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}