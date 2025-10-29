import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour le rapport de supervision
class SupervisionReport {
  final String id;
  final String projectId;
  final String title;
  final DateTime visitDate;
  final String supervisor; // Nom du superviseur
  final List<String> observations; // Observations faites
  final List<String> recommendations; // Recommandations
  final String conformityLevel; // conforme, non_conforme, partiellement_conforme
  final List<String> photos; // URLs des photos
  final Map<String, dynamic> checkpoints; // Points de contrôle
  final String? comments; // Commentaires additionnels
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SupervisionReport({
    required this.id,
    required this.projectId,
    required this.title,
    required this.visitDate,
    required this.supervisor,
    required this.observations,
    required this.recommendations,
    required this.conformityLevel,
    required this.photos,
    required this.checkpoints,
    this.comments,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  factory SupervisionReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupervisionReport(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      title: data['title'] ?? '',
      visitDate: (data['visitDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      supervisor: data['supervisor'] ?? '',
      observations: List<String>.from(data['observations'] ?? []),
      recommendations: List<String>.from(data['recommendations'] ?? []),
      conformityLevel: data['conformityLevel'] ?? 'partiellement_conforme',
      photos: List<String>.from(data['photos'] ?? []),
      checkpoints: Map<String, dynamic>.from(data['checkpoints'] ?? {}),
      comments: data['comments'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'title': title,
      'visitDate': Timestamp.fromDate(visitDate),
      'supervisor': supervisor,
      'observations': observations,
      'recommendations': recommendations,
      'conformityLevel': conformityLevel,
      'photos': photos,
      'checkpoints': checkpoints,
      'comments': comments,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
