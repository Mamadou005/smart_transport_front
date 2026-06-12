class LocalisationModel {
  final int id;
  final double latitude;
  final double longitude;
  final String horodatage;

  LocalisationModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.horodatage,
  });

  factory LocalisationModel.fromJson(Map<String, dynamic> json) =>
      LocalisationModel(
        id:          json['id'],
        latitude:    double.parse(json['latitude'].toString()),
        longitude:   double.parse(json['longitude'].toString()),
        horodatage:  json['horodatage'] ?? json['created_at'],
      );
}

class BagageModel {
  final int id;
  final String description;
  final double poids;
  final String codeQr;
  final String statut;
  final String? reservationCode;
  final String? voyageOrigine;
  final String? voyageDestination;
  final LocalisationModel? derniereLocalisation;
  final List<LocalisationModel> localisations;

  BagageModel({
    required this.id,
    required this.description,
    required this.poids,
    required this.codeQr,
    required this.statut,
    this.reservationCode,
    this.voyageOrigine,
    this.voyageDestination,
    this.derniereLocalisation,
    this.localisations = const [],
  });

  factory BagageModel.fromJson(Map<String, dynamic> json) {
    final reservation = json['reservation'];
    final voyage      = reservation?['voyage'];

    return BagageModel(
      id:          json['id'],
      description: json['description'] ?? 'Bagage',
      poids:       double.parse(json['poids'].toString()),
      codeQr:      json['code_qr'],
      statut:      json['statut'],
      reservationCode:    reservation?['code_qr'],
      voyageOrigine:      voyage?['origine'],
      voyageDestination:  voyage?['destination'],
      derniereLocalisation: json['derniere_localisation'] != null
          ? LocalisationModel.fromJson(json['derniere_localisation'])
          : null,
      localisations: json['localisations'] != null
          ? (json['localisations'] as List)
          .map((l) => LocalisationModel.fromJson(l))
          .toList()
          : [],
    );
  }
}