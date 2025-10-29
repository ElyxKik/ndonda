class Dechet {
  final String id;
  final String projectId;
  final DateTime date;
  final String typeDechet; // 'dangereux', 'non_dangereux', 'recyclable', 'organique'
  final String description;
  final double quantite;
  final String unite; // 'kg', 'tonnes', 'm3', 'unites'
  final String modeGestion; // 'recyclage', 'enfouissement', 'incineration', 'valorisation'
  final String? destination;
  final List<String> photos;
  final String? commentaire;
  final DateTime createdAt;

  Dechet({
    required this.id,
    required this.projectId,
    required this.date,
    required this.typeDechet,
    required this.description,
    required this.quantite,
    required this.unite,
    required this.modeGestion,
    this.destination,
    this.photos = const [],
    this.commentaire,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'date': date.toIso8601String(),
      'typeDechet': typeDechet,
      'description': description,
      'quantite': quantite,
      'unite': unite,
      'modeGestion': modeGestion,
      'destination': destination,
      'photos': photos.join(','),
      'commentaire': commentaire,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Dechet.fromMap(Map<String, dynamic> map) {
    return Dechet(
      id: map['id'],
      projectId: map['projectId'],
      date: DateTime.parse(map['date']),
      typeDechet: map['typeDechet'],
      description: map['description'],
      quantite: map['quantite'],
      unite: map['unite'],
      modeGestion: map['modeGestion'],
      destination: map['destination'],
      photos: map['photos'] != null && map['photos'].isNotEmpty
          ? map['photos'].split(',')
          : [],
      commentaire: map['commentaire'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
