class Compensation {
  final String id;
  final String projectId;
  final DateTime date;
  final String beneficiaire;
  final String typeActif; // 'terrain', 'culture', 'batiment', 'autre'
  final String description;
  final double montant;
  final String devise;
  final String statut; // 'en_attente', 'partielle', 'complete'
  final String? localisation;
  final double? latitude;
  final double? longitude;
  final List<String> photos;
  final String? commentaire;
  final DateTime createdAt;

  Compensation({
    required this.id,
    required this.projectId,
    required this.date,
    required this.beneficiaire,
    required this.typeActif,
    required this.description,
    required this.montant,
    required this.devise,
    required this.statut,
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
      'beneficiaire': beneficiaire,
      'typeActif': typeActif,
      'description': description,
      'montant': montant,
      'devise': devise,
      'statut': statut,
      'localisation': localisation,
      'latitude': latitude,
      'longitude': longitude,
      'photos': photos.join(','),
      'commentaire': commentaire,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Compensation.fromMap(Map<String, dynamic> map) {
    return Compensation(
      id: map['id'],
      projectId: map['projectId'],
      date: DateTime.parse(map['date']),
      beneficiaire: map['beneficiaire'],
      typeActif: map['typeActif'],
      description: map['description'],
      montant: map['montant'],
      devise: map['devise'],
      statut: map['statut'],
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
