class Audit {
  final String id;
  final String projectId;
  final DateTime date;
  final String statut; // 'interne', 'externe', 'supervision'
  final String titre;
  final String responsable;
  final String? observations;
  final List<String> photos;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  Audit({
    required this.id,
    required this.projectId,
    required this.date,
    required this.statut,
    required this.titre,
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
      'statut': statut,
      'titre': titre,
      'responsable': responsable,
      'observations': observations,
      'photos': photos.join(','),
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Audit.fromMap(Map<String, dynamic> map) {
    return Audit(
      id: map['id'],
      projectId: map['projectId'],
      date: DateTime.parse(map['date']),
      statut: map['statut'],
      titre: map['titre'],
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
