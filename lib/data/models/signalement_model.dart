import 'bagage_model.dart';

class SignalementModel {
  final int id;
  final String description;
  final String? lieuDernierVu;
  final String statut;
  final String createdAt;
  final BagageModel? bagage;

  SignalementModel({
    required this.id,
    required this.description,
    this.lieuDernierVu,
    required this.statut,
    required this.createdAt,
    this.bagage,
  });

  factory SignalementModel.fromJson(Map<String, dynamic> json) =>
      SignalementModel(
        id:            json['id'],
        description:   json['description'],
        lieuDernierVu: json['lieu_dernier_vu'],
        statut:        json['statut'],
        createdAt:     json['created_at'],
        bagage: json['bagage'] != null
            ? BagageModel.fromJson(json['bagage'])
            : null,
      );
}