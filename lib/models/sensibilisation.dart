class Sensibilisation {
  final String id;
  final String projectId;
  final DateTime date;
  final String theme; // 'IST', 'VIH_SIDA', 'hygiene', 'autre'
  final String type; // 'formation', 'causerie', 'affichage', 'distribution'
  final int nombreParticipants;
  final int nombreHommes;
  final int nombreFemmes;
  final String? intervenant;
  final String? materielDistribue;
  final int? quantiteMateriel;
  final List<String> photos;
  final String? commentaire;
  final DateTime createdAt;

  Sensibilisation({
    required this.id,
    required this.projectId,
    required this.date,
    required this.theme,
    required this.type,
    required this.nombreParticipants,
    required this.nombreHommes,
    required this.nombreFemmes,
    this.intervenant,
    this.materielDistribue,
    this.quantiteMateriel,
    this.photos = const [],
    this.commentaire,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'date': date.toIso8601String(),
      'theme': theme,
      'type': type,
      'nombreParticipants': nombreParticipants,
      'nombreHommes': nombreHommes,
      'nombreFemmes': nombreFemmes,
      'intervenant': intervenant,
      'materielDistribue': materielDistribue,
      'quantiteMateriel': quantiteMateriel,
      'photos': photos.join(','),
      'commentaire': commentaire,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Sensibilisation.fromMap(Map<String, dynamic> map) {
    return Sensibilisation(
      id: map['id'],
      projectId: map['projectId'],
      date: DateTime.parse(map['date']),
      theme: map['theme'],
      type: map['type'],
      nombreParticipants: map['nombreParticipants'],
      nombreHommes: map['nombreHommes'],
      nombreFemmes: map['nombreFemmes'],
      intervenant: map['intervenant'],
      materielDistribue: map['materielDistribue'],
      quantiteMateriel: map['quantiteMateriel'],
      photos: map['photos'] != null && map['photos'].isNotEmpty
          ? map['photos'].split(',')
          : [],
      commentaire: map['commentaire'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
