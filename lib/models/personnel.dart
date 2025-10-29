class Personnel {
  final String id;
  final String projectId;
  final DateTime periode;
  final String categorie; // 'cadres', 'techniciens', 'ouvriers', 'autres'
  final int nombreHommes;
  final int nombreFemmes;
  final String? nationalite;
  final String? fonction;
  final String? commentaire;
  final DateTime createdAt;

  Personnel({
    required this.id,
    required this.projectId,
    required this.periode,
    required this.categorie,
    required this.nombreHommes,
    required this.nombreFemmes,
    this.nationalite,
    this.fonction,
    this.commentaire,
    required this.createdAt,
  });

  int get total => nombreHommes + nombreFemmes;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'periode': periode.toIso8601String(),
      'categorie': categorie,
      'nombreHommes': nombreHommes,
      'nombreFemmes': nombreFemmes,
      'nationalite': nationalite,
      'fonction': fonction,
      'commentaire': commentaire,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Personnel.fromMap(Map<String, dynamic> map) {
    return Personnel(
      id: map['id'],
      projectId: map['projectId'],
      periode: DateTime.parse(map['periode']),
      categorie: map['categorie'],
      nombreHommes: map['nombreHommes'],
      nombreFemmes: map['nombreFemmes'],
      nationalite: map['nationalite'],
      fonction: map['fonction'],
      commentaire: map['commentaire'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
