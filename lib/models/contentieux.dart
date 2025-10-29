class Contentieux {
  final String id;
  final String projectId;
  final DateTime dateOuverture;
  final String objet;
  final String parties;
  final String nature; // 'foncier', 'commercial', 'social', 'environnemental', 'autre'
  final String statut; // 'ouvert', 'en_cours', 'resolu', 'en_appel'
  final String? modeResolution; // 'amiable', 'mediation', 'arbitrage', 'judiciaire'
  final DateTime? dateResolution;
  final String? decision;
  final List<String> photos;
  final String? commentaire;
  final DateTime createdAt;

  Contentieux({
    required this.id,
    required this.projectId,
    required this.dateOuverture,
    required this.objet,
    required this.parties,
    required this.nature,
    required this.statut,
    this.modeResolution,
    this.dateResolution,
    this.decision,
    this.photos = const [],
    this.commentaire,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'dateOuverture': dateOuverture.toIso8601String(),
      'objet': objet,
      'parties': parties,
      'nature': nature,
      'statut': statut,
      'modeResolution': modeResolution,
      'dateResolution': dateResolution?.toIso8601String(),
      'decision': decision,
      'photos': photos.join(','),
      'commentaire': commentaire,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Contentieux.fromMap(Map<String, dynamic> map) {
    return Contentieux(
      id: map['id'],
      projectId: map['projectId'],
      dateOuverture: DateTime.parse(map['dateOuverture']),
      objet: map['objet'],
      parties: map['parties'],
      nature: map['nature'],
      statut: map['statut'],
      modeResolution: map['modeResolution'],
      dateResolution: map['dateResolution'] != null
          ? DateTime.parse(map['dateResolution'])
          : null,
      decision: map['decision'],
      photos: map['photos'] != null && map['photos'].isNotEmpty
          ? map['photos'].split(',')
          : [],
      commentaire: map['commentaire'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
