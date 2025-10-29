import 'package:cloud_firestore/cloud_firestore.dart';

class ModuleComment {
  final String id;
  final String documentId;
  final String collectionName;
  final String projectId;
  final String userId;
  final String userName;
  final String userRole;
  final String comment;
  final DateTime createdAt;

  ModuleComment({
    required this.id,
    required this.documentId,
    required this.collectionName,
    required this.projectId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.comment,
    required this.createdAt,
  });

  factory ModuleComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ModuleComment(
      id: doc.id,
      documentId: data['documentId'] ?? '',
      collectionName: data['collectionName'] ?? '',
      projectId: data['projectId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Utilisateur',
      userRole: data['userRole'] ?? '',
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'documentId': documentId,
      'collectionName': collectionName,
      'projectId': projectId,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'comment': comment,
      'createdAt': createdAt,
    };
  }
}
