import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour le rapport d'activité
class ActivityReport {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // en_cours, termine, en_attente
  final List<String> activities; // Liste des activités réalisées
  final Map<String, int> statistics; // Statistiques (incidents, équipements, etc.)
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ActivityReport({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.activities,
    required this.statistics,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  factory ActivityReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityReport(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'en_cours',
      activities: List<String>.from(data['activities'] ?? []),
      statistics: Map<String, int>.from(data['statistics'] ?? {}),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status,
      'activities': activities,
      'statistics': statistics,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
