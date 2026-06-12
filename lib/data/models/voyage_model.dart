class VoyageModel {
  final int    id;
  final String origine;
  final String destination;
  final String dateDepart;
  final String dateArrivee;
  final String typeTransport;
  final String statut;
  final int    capacite;
  final double? prix;   // ✅ Ajoute ce champ
  final String? devise;

  VoyageModel({
    required this.id,
    required this.origine,
    required this.destination,
    required this.dateDepart,
    required this.dateArrivee,
    required this.typeTransport,
    required this.statut,
    required this.capacite,
    this.prix,            // ✅
    this.devise,
  });

  factory VoyageModel.fromJson(Map<String, dynamic> json) {
    return VoyageModel(
      id:            json['id'],
      origine:       json['origine']       ?? '',
      destination:   json['destination']   ?? '',
      dateDepart:    json['date_depart']   ?? '',
      dateArrivee:   json['date_arrivee']  ?? '',
      typeTransport: json['type_transport'] ?? 'routier',
      statut:        json['statut']        ?? 'planifie',
      capacite:      json['capacite']      ?? 0,
      // ✅ Parse le prix depuis l'API
      prix:  json['prix'] != null
          ? double.tryParse(json['prix'].toString())
          : null,
      devise: json['devise'] ?? 'XOF',
    );
  }

  Map<String, dynamic> toJson() => {
    'id':             id,
    'origine':        origine,
    'destination':    destination,
    'date_depart':    dateDepart,
    'date_arrivee':   dateArrivee,
    'type_transport': typeTransport,
    'statut':         statut,
    'capacite':       capacite,
    'prix':           prix,
    'devise':         devise,
  };
}