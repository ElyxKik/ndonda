import 'package:cloud_firestore/cloud_firestore.dart';

class HSEIndicator {
  final String id;
  final String projectId;
  final String userId;
  final DateTime createdAt;
  final String responsableHSE;
  final String mois;
  final String zone;
  final DateTime? dateSubmission;
  final Map<String, String> environmentalIndicators;
  final Map<String, String> socialIndicators;
  final Map<String, int> quantitativeIndicators;
  final String observations;

  HSEIndicator({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.createdAt,
    required this.responsableHSE,
    required this.mois,
    required this.zone,
    this.dateSubmission,
    required this.environmentalIndicators,
    required this.socialIndicators,
    required this.quantitativeIndicators,
    required this.observations,
  });

  factory HSEIndicator.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HSEIndicator(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      responsableHSE: data['responsableHSE'] ?? '',
      mois: data['mois'] ?? '',
      zone: data['zone'] ?? '',
      dateSubmission: (data['dateSubmission'] as Timestamp?)?.toDate(),
      environmentalIndicators: Map<String, String>.from(data['environmentalIndicators'] ?? {}),
      socialIndicators: Map<String, String>.from(data['socialIndicators'] ?? {}),
      quantitativeIndicators: Map<String, int>.from(data['quantitativeIndicators'] ?? {}),
      observations: data['observations'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'userId': userId,
      'createdAt': createdAt,
      'responsableHSE': responsableHSE,
      'mois': mois,
      'zone': zone,
      'dateSubmission': dateSubmission,
      'environmentalIndicators': environmentalIndicators,
      'socialIndicators': socialIndicators,
      'quantitativeIndicators': quantitativeIndicators,
      'observations': observations,
    };
  }
}
