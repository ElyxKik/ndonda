class Consultation {
  final String id;
  final String projectId;
  final DateTime date;
  final String type; // 'reunion', 'affichage', 'radio', 'autre'
  final String sujet;
  final int nombreParticipants;
  final int nombreHommes;
  final int nombreFemmes;
  final String? localisation;
  final String? principauxPoints;
  final List<String> photos;
  final String? commentaire;
  final DateTime createdAt;

  Consultation({
    required this.id,
    required this.projectId,
    required this.date,
    required this.type,
    required this.sujet,
    required this.nombreParticipants,
    required this.nombreHommes,
    required this.nombreFemmes,
    this.localisation,
    this.principauxPoints,
    this.photos = const [],
    this.commentaire,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'date': date.toIso8601String(),
      'type': type,
      'sujet': sujet,
      'nombreParticipants': nombreParticipants,
      'nombreHommes': nombreHommes,
      'nombreFemmes': nombreFemmes,
      'localisation': localisation,
      'principauxPoints': principauxPoints,
      'photos': photos.join(','),
      'commentaire': commentaire,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Consultation.fromMap(Map<String, dynamic> map) {
    return Consultation(
      id: map['id'],
      projectId: map['projectId'],
      date: DateTime.parse(map['date']),
      type: map['type'],
      sujet: map['sujet'],
      nombreParticipants: map['nombreParticipants'],
      nombreHommes: map['nombreHommes'],
      nombreFemmes: map['nombreFemmes'],
      localisation: map['localisation'],
      principauxPoints: map['principauxPoints'],
      photos: map['photos'] != null && map['photos'].isNotEmpty
          ? map['photos'].split(',')
          : [],
      commentaire: map['commentaire'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
