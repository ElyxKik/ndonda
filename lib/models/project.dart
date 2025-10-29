class Project {
  final String id;
  final String nom;
  final String localisation;
  final String maitreOuvrage;
  final String entreprise;
  final String consultant;
  final DateTime dateDebut;
  final DateTime? dateFin;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userId;
  final bool archived;

  Project({
    required this.id,
    required this.nom,
    required this.localisation,
    required this.maitreOuvrage,
    required this.entreprise,
    required this.consultant,
    required this.dateDebut,
    this.dateFin,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
    this.archived = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'localisation': localisation,
      'maitreOuvrage': maitreOuvrage,
      'entreprise': entreprise,
      'consultant': consultant,
      'dateDebut': dateDebut.toIso8601String(),
      'dateFin': dateFin?.toIso8601String(),
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
      'archived': archived,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      localisation: map['localisation'] ?? '',
      maitreOuvrage: map['maitreOuvrage'] ?? '',
      entreprise: map['entreprise'] ?? '',
      consultant: map['consultant'] ?? '',
      dateDebut: map['dateDebut'] != null ? DateTime.parse(map['dateDebut']) : DateTime.now(),
      dateFin: map['dateFin'] != null ? DateTime.parse(map['dateFin']) : null,
      description: map['description'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
      userId: map['userId'],
      archived: map['archived'] ?? false,
    );
  }

  Project copyWith({
    String? id,
    String? nom,
    String? localisation,
    String? maitreOuvrage,
    String? entreprise,
    String? consultant,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    bool? archived,
  }) {
    return Project(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      localisation: localisation ?? this.localisation,
      maitreOuvrage: maitreOuvrage ?? this.maitreOuvrage,
      entreprise: entreprise ?? this.entreprise,
      consultant: consultant ?? this.consultant,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      archived: archived ?? this.archived,
    );
  }
}
