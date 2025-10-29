class Equipement {
  final String id;
  final String projectId;
  final DateTime date;
  final String typeEquipement; // 'EPI', 'EPC'
  final String designation;
  final int quantiteDemandee;
  final int quantiteFournie;
  final String? fournisseur;
  final String statut; // 'demande', 'partiel', 'complet'
  final List<String> photos;
  final String? commentaire;
  final DateTime createdAt;

  Equipement({
    required this.id,
    required this.projectId,
    required this.date,
    required this.typeEquipement,
    required this.designation,
    required this.quantiteDemandee,
    required this.quantiteFournie,
    this.fournisseur,
    required this.statut,
    this.photos = const [],
    this.commentaire,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'date': date.toIso8601String(),
      'typeEquipement': typeEquipement,
      'designation': designation,
      'quantiteDemandee': quantiteDemandee,
      'quantiteFournie': quantiteFournie,
      'fournisseur': fournisseur,
      'statut': statut,
      'photos': photos.join(','),
      'commentaire': commentaire,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Equipement.fromMap(Map<String, dynamic> map) {
    return Equipement(
      id: map['id'],
      projectId: map['projectId'],
      date: DateTime.parse(map['date']),
      typeEquipement: map['typeEquipement'],
      designation: map['designation'],
      quantiteDemandee: map['quantiteDemandee'],
      quantiteFournie: map['quantiteFournie'],
      fournisseur: map['fournisseur'],
      statut: map['statut'],
      photos: map['photos'] != null && map['photos'].isNotEmpty
          ? map['photos'].split(',')
          : [],
      commentaire: map['commentaire'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
