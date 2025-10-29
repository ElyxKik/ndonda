import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour une photo dans le rapport photo
class PhotoReportItem {
  final String id;
  final String projectId;
  final String imageUrl;
  final String legend; // Légende de la photo
  final String module; // Module d'origine (incidents, equipements, etc.)
  final String moduleItemId; // ID de l'élément du module
  final DateTime createdAt;
  final String createdBy;
  final Map<String, dynamic>? metadata; // Données supplémentaires

  PhotoReportItem({
    required this.id,
    required this.projectId,
    required this.imageUrl,
    required this.legend,
    required this.module,
    required this.moduleItemId,
    required this.createdAt,
    required this.createdBy,
    this.metadata,
  });

  factory PhotoReportItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PhotoReportItem(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      legend: data['legend'] ?? '',
      module: data['module'] ?? '',
      moduleItemId: data['moduleItemId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'imageUrl': imageUrl,
      'legend': legend,
      'module': module,
      'moduleItemId': moduleItemId,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'metadata': metadata,
    };
  }
}
