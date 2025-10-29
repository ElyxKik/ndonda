class Plainte {
  final String id;
  final String projectId;
  final DateTime dateReception;
  final String plaignant;
  final String contact;
  final String objet;
  final String description;
  final String categorie; // 'environnement', 'social', 'bruit', 'poussiere', 'autre'
  final String priorite; // 'faible', 'moyenne', 'haute', 'urgente'
  final String statut; // 'enregistree', 'en_traitement', 'resolue', 'rejetee'
  final String? actionMenee;
  final DateTime? dateResolution;
  final String? satisfaction; // 'satisfait', 'partiellement_satisfait', 'insatisfait'
  final List<String> photos;
  final String? commentaire;
  final DateTime createdAt;

  Plainte({
    required this.id,
    required this.projectId,
    required this.dateReception,
    required this.plaignant,
    required this.contact,
    required this.objet,
    required this.description,
    required this.categorie,
    required this.priorite,
    required this.statut,
    this.actionMenee,
    this.dateResolution,
    this.satisfaction,
    this.photos = const [],
    this.commentaire,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'dateReception': dateReception.toIso8601String(),
      'plaignant': plaignant,
      'contact': contact,
      'objet': objet,
      'description': description,
      'categorie': categorie,
      'priorite': priorite,
      'statut': statut,
      'actionMenee': actionMenee,
      'dateResolution': dateResolution?.toIso8601String(),
      'satisfaction': satisfaction,
      'photos': photos.join(','),
      'commentaire': commentaire,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Plainte.fromMap(Map<String, dynamic> map) {
    return Plainte(
      id: map['id'],
      projectId: map['projectId'],
      dateReception: DateTime.parse(map['dateReception']),
      plaignant: map['plaignant'],
      contact: map['contact'],
      objet: map['objet'],
      description: map['description'],
      categorie: map['categorie'],
      priorite: map['priorite'],
      statut: map['statut'],
      actionMenee: map['actionMenee'],
      dateResolution: map['dateResolution'] != null
          ? DateTime.parse(map['dateResolution'])
          : null,
      satisfaction: map['satisfaction'],
      photos: map['photos'] != null && map['photos'].isNotEmpty
          ? map['photos'].split(',')
          : [],
      commentaire: map['commentaire'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
