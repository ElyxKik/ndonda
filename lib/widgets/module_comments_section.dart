import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/module_comment.dart';
import '../models/user_role.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

class ModuleCommentsSection extends StatefulWidget {
  final String projectId;
  final String documentId;
  final String collectionName;
  final bool readOnly;

  const ModuleCommentsSection({
    super.key,
    required this.projectId,
    required this.documentId,
    required this.collectionName,
    this.readOnly = false,
  });

  @override
  State<ModuleCommentsSection> createState() => _ModuleCommentsSectionState();
}

class _ModuleCommentsSectionState extends State<ModuleCommentsSection> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final user = _auth.currentUser;
      final provider = Provider.of<AppProvider>(context, listen: false);

      if (user == null) throw Exception('Utilisateur non connecté');

      // Ajouter le commentaire
      await _firestore
          .collection('projects')
          .doc(widget.projectId)
          .collection('moduleComments')
          .add({
        'documentId': widget.documentId,
        'collectionName': widget.collectionName,
        'projectId': widget.projectId,
        'userId': user.uid,
        'userName': user.displayName ?? 'Utilisateur',
        'userRole': provider.userRole.displayName,
        'comment': _commentController.text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Créer une notification pour les consultants
      await _firestore
          .collection('notifications')
          .add({
        'projectId': widget.projectId,
        'type': 'module_comment',
        'title': 'Nouveau commentaire',
        'message': '${user.displayName} a ajouté un commentaire sur ${widget.collectionName}',
        'documentId': widget.documentId,
        'collectionName': widget.collectionName,
        'userId': user.uid,
        'userName': user.displayName,
        'userRole': provider.userRole.displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      _commentController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commentaire ajouté avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Commentaires et Observations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Section commentaires
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('projects')
                .doc(widget.projectId)
                .collection('moduleComments')
                .where('documentId', isEqualTo: widget.documentId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final comments = snapshot.data?.docs ?? [];

              if (comments.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    'Aucun commentaire pour le moment',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = ModuleComment.fromFirestore(comments[index]);
                  return _buildCommentCard(comment);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Champ de commentaire (si pas en lecture seule)
        if (!widget.readOnly)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajouter un commentaire',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    hintText: 'Écrivez votre commentaire ou observation...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitComment,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      _isSubmitting ? 'Envoi...' : 'Envoyer le commentaire',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCommentCard(ModuleComment comment) {
    final roleColor = _getRoleColor(comment.userRole);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: roleColor.withOpacity(0.2),
                radius: 20,
                child: Icon(
                  _getRoleIcon(comment.userRole),
                  color: roleColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      comment.userRole,
                      style: TextStyle(
                        fontSize: 12,
                        color: roleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(comment.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment.comment,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'administrateur':
        return Colors.pink;
      case 'consultant':
        return Colors.blue;
      case 'supervision/bailleur':
        return Colors.orange;
      case 'visiteur':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'administrateur':
        return Icons.admin_panel_settings;
      case 'consultant':
        return Icons.business_center;
      case 'supervision/bailleur':
        return Icons.supervised_user_circle;
      case 'visiteur':
        return Icons.visibility;
      default:
        return Icons.person;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
