class Evenement {
  final String id;
  final String projectId;
  final DateTime date;
  final String titre;
  final String description;
  final String type; // 'incident', 'reunion', 'visite', 'autre'
  final String? localisation;
  final double? latitude;
  final double? longitude;
  final List<String> photos;
  final String? commentaire;
  final DateTime createdAt;

  Evenement({
    required this.id,
    required this.projectId,
    required this.date,
    required this.titre,
    required this.description,
    required this.type,
    this.localisation,
    this.latitude,
    this.longitude,
    this.photos = const [],
    this.commentaire,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'date': date.toIso8601String(),
      'titre': titre,
      'description': description,
      'type': type,
      'localisation': localisation,
      'latitude': latitude,
      'longitude': longitude,
      'photos': photos.join(','),
      'commentaire': commentaire,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Evenement.fromMap(Map<String, dynamic> map) {
    return Evenement(
      id: map['id'],
      projectId: map['projectId'],
      date: DateTime.parse(map['date']),
      titre: map['titre'],
      description: map['description'],
      type: map['type'],
      localisation: map['localisation'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      photos: map['photos'] != null && map['photos'].isNotEmpty
          ? map['photos'].split(',')
          : [],
      commentaire: map['commentaire'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
