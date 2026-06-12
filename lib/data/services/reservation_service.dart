import '../models/reservation_model.dart';
import 'api_service.dart';

class ReservationService {
  final ApiService _api = ApiService();

  Future<List<ReservationModel>> getMesReservations() async {
    final response = await _api.get('/reservations');
    return (response.data as List)
        .map((r) => ReservationModel.fromJson(r))
        .toList();
  }

  Future<ReservationModel> creerReservation(int voyageId) async {
    final response = await _api.post('/reservations', {
      'voyage_id': voyageId,
    });
    return ReservationModel.fromJson(response.data);
  }

  Future<void> annulerReservation(int id) async {
    await _api.delete('/reservations/$id');
  }
}