import 'voyage_model.dart';

class ReservationModel {
  final int id;
  final String codeQr;
  final String statut;
  final String createdAt;
  final VoyageModel? voyage;

  ReservationModel({
    required this.id,
    required this.codeQr,
    required this.statut,
    required this.createdAt,
    this.voyage,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) =>
      ReservationModel(
        id:        json['id'],
        codeQr:    json['code_qr'],
        statut:    json['statut'],
        createdAt: json['created_at'],
        voyage: json['voyage'] != null
            ? VoyageModel.fromJson(json['voyage'])
            : null,
      );
}