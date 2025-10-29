import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour le rapport de consultant
class ConsultantReport {
  final String id;
  final String projectId;
  final String title;
  final String consultant; // Nom du consultant
  final DateTime reportDate;
  final String executiveSummary; // Résumé exécutif
  final List<String> findings; // Constatations
  final List<String> recommendations; // Recommandations
  final Map<String, dynamic> analysis; // Analyses détaillées
  final List<String> attachments; // URLs des pièces jointes
  final String status; // brouillon, final, valide
  final String? conclusion;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ConsultantReport({
    required this.id,
    required this.projectId,
    required this.title,
    required this.consultant,
    required this.reportDate,
    required this.executiveSummary,
    required this.findings,
    required this.recommendations,
    required this.analysis,
    required this.attachments,
    required this.status,
    this.conclusion,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  factory ConsultantReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConsultantReport(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      title: data['title'] ?? '',
      consultant: data['consultant'] ?? '',
      reportDate: (data['reportDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      executiveSummary: data['executiveSummary'] ?? '',
      findings: List<String>.from(data['findings'] ?? []),
      recommendations: List<String>.from(data['recommendations'] ?? []),
      analysis: Map<String, dynamic>.from(data['analysis'] ?? {}),
      attachments: List<String>.from(data['attachments'] ?? []),
      status: data['status'] ?? 'brouillon',
      conclusion: data['conclusion'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'title': title,
      'consultant': consultant,
      'reportDate': Timestamp.fromDate(reportDate),
      'executiveSummary': executiveSummary,
      'findings': findings,
      'recommendations': recommendations,
      'analysis': analysis,
      'attachments': attachments,
      'status': status,
      'conclusion': conclusion,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
