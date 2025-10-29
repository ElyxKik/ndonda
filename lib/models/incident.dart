class Incident {
  final String id;
  final String projectId;
  final DateTime date;
  final String type; // 'maladie', 'accident_travail', 'accident_circulation', 'autre'
  final String gravite; // 'leger', 'moyen', 'grave', 'mortel'
  final String description;
  final String personneAffectee;
  final String? fonction;
  final String mesuresPrises;
  final int joursArretTravail;
  final String? localisation;
  final List<String> photos;
  final String? commentaire;
  final DateTime createdAt;

  Incident({
    required this.id,
    required this.projectId,
    required this.date,
    required this.type,
    required this.gravite,
    required this.description,
    required this.personneAffectee,
    this.fonction,
    required this.mesuresPrises,
    required this.joursArretTravail,
    this.localisation,
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
      'gravite': gravite,
      'description': description,
      'personneAffectee': personneAffectee,
      'fonction': fonction,
      'mesuresPrises': mesuresPrises,
      'joursArretTravail': joursArretTravail,
      'localisation': localisation,
      'photos': photos.join(','),
      'commentaire': commentaire,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Incident.fromMap(Map<String, dynamic> map) {
    return Incident(
      id: map['id'],
      projectId: map['projectId'],
      date: DateTime.parse(map['date']),
      type: map['type'],
      gravite: map['gravite'],
      description: map['description'],
      personneAffectee: map['personneAffectee'],
      fonction: map['fonction'],
      mesuresPrises: map['mesuresPrises'],
      joursArretTravail: map['joursArretTravail'],
      localisation: map['localisation'],
      photos: map['photos'] != null && map['photos'].isNotEmpty
          ? map['photos'].split(',')
          : [],
      commentaire: map['commentaire'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
