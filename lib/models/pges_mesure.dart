class PgesMesure {
  final String id;
  final String projectId;
  final DateTime date;
  final String categorie; // 'environnement', 'social', 'sante_securite'
  final String mesure;
  final String statut; // 'non_commence', 'en_cours', 'termine', 'non_conforme'
  final String responsable;
  final String? observations;
  final List<String> photos;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  PgesMesure({
    required this.id,
    required this.projectId,
    required this.date,
    required this.categorie,
    required this.mesure,
    required this.statut,
    required this.responsable,
    this.observations,
    this.photos = const [],
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'date': date.toIso8601String(),
      'categorie': categorie,
      'mesure': mesure,
      'statut': statut,
      'responsable': responsable,
      'observations': observations,
      'photos': photos.join(','),
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PgesMesure.fromMap(Map<String, dynamic> map) {
    return PgesMesure(
      id: map['id'],
      projectId: map['projectId'],
      date: DateTime.parse(map['date']),
      categorie: map['categorie'],
      mesure: map['mesure'],
      statut: map['statut'],
      responsable: map['responsable'],
      observations: map['observations'],
      photos: map['photos'] != null && map['photos'].isNotEmpty
          ? map['photos'].split(',')
          : [],
      latitude: map['latitude'],
      longitude: map['longitude'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
