import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/hse_indicator.dart';
import '../models/user_role.dart';
import '../services/user_role_service.dart';
import '../utils/constants.dart';

class HSEIndicatorDetailScreen extends StatefulWidget {
  final String indicatorId;
  final String projectId;

  const HSEIndicatorDetailScreen({
    super.key,
    required this.indicatorId,
    required this.projectId,
  });

  @override
  State<HSEIndicatorDetailScreen> createState() => _HSEIndicatorDetailScreenState();
}

class _HSEIndicatorDetailScreenState extends State<HSEIndicatorDetailScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _roleService = UserRoleService.instance;
  
  UserRole? _userRole;
  bool _isLoading = true;
  late TextEditingController _commentController;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _loadUserRole();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      final role = await _roleService.getUserRole(userId);
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userName = userDoc.data()?['displayName'] ?? _auth.currentUser?.email ?? 'Utilisateur';
      
      setState(() {
        _userRole = role;
        _currentUserName = userName;
        _isLoading = false;
      });
    } else {
      setState(() {
        _userRole = UserRole.visiteur;
        _isLoading = false;
      });
    }
  }

  bool get _canModify {
    return _userRole == UserRole.admin || _userRole == UserRole.consultant;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Détails Indicateur HSE'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Détails Indicateur HSE'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: _canModify
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditDialog(),
                  tooltip: 'Modifier',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDelete(),
                  tooltip: 'Supprimer',
                ),
              ]
            : null,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('hseIndicators')
            .doc(widget.indicatorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Indicateur non trouvé'),
            );
          }

          final indicator = HSEIndicator.fromFirestore(snapshot.data!);
          return _buildIndicatorDetails(indicator);
        },
      ),
    );
  }

  Widget _buildIndicatorDetails(HSEIndicator indicator) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          _buildHeader(indicator),
          
          const SizedBox(height: 16),
          
          // Informations générales
          _buildSection(
            title: 'Informations Générales',
            icon: Icons.info_outline,
            children: [
              _buildInfoRow('Responsable HSE', indicator.responsableHSE, Icons.person),
              _buildInfoRow('Mois', indicator.mois, Icons.calendar_month),
              _buildInfoRow('Zone', indicator.zone, Icons.location_on),
              if (indicator.dateSubmission != null)
                _buildInfoRow(
                  'Date de soumission',
                  '${indicator.dateSubmission!.day}/${indicator.dateSubmission!.month}/${indicator.dateSubmission!.year}',
                  Icons.event,
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Indicateurs environnementaux
          _buildSection(
            title: 'Indicateurs Environnementaux',
            icon: Icons.eco,
            children: [
              _buildIndicatorsList(indicator.environmentalIndicators),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Indicateurs sociaux
          _buildSection(
            title: 'Indicateurs Sociaux et de Santé',
            icon: Icons.people,
            children: [
              _buildIndicatorsList(indicator.socialIndicators),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Indicateurs quantitatifs
          _buildSection(
            title: 'Indicateurs Quantitatifs',
            icon: Icons.bar_chart,
            children: [
              _buildQuantitativeIndicators(indicator.quantitativeIndicators),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Observations
          if (indicator.observations.isNotEmpty)
            _buildSection(
              title: 'Observations',
              icon: Icons.comment,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    indicator.observations,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 16),
          
          // Section Commentaires
          _buildCommentsSection(indicator),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(HSEIndicator indicator) {
    final envCompliance = indicator.environmentalIndicators.values
        .where((v) => v == 'Oui')
        .length;
    final socialCompliance = indicator.socialIndicators.values
        .where((v) => v == 'Oui')
        .length;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assessment, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suivi HSE - ${indicator.mois}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      indicator.zone,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Conformité Env.',
                  '$envCompliance/9',
                  Colors.white.withOpacity(0.2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Conformité Sociale',
                  '$socialCompliance/8',
                  Colors.white.withOpacity(0.2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Non renseigné' : value,
                  style: TextStyle(
                    fontSize: 14,
                    color: value.isEmpty ? Colors.grey[400] : Colors.grey[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorsList(Map<String, String> indicators) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: indicators.entries.map((entry) {
          final color = _getStatusColor(entry.value);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuantitativeIndicators(Map<String, int> indicators) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: indicators.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'oui':
        return Colors.green;
      case 'non':
        return Colors.red;
      case 'partiel':
        return Colors.orange;
      case 'n.a':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _showEditDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HSEIndicatorEditScreen(
          indicatorId: widget.indicatorId,
          projectId: widget.projectId,
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cet indicateur HSE ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteIndicator();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteIndicator() async {
    try {
      await _firestore
          .collection('hseIndicators')
          .doc(widget.indicatorId)
          .delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Indicateur supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
    }
  }

  Widget _buildCommentsSection(HSEIndicator indicator) {
    final canComment = _userRole == UserRole.supervision;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Commentaires et Remarques',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Formulaire de commentaire (superviseur uniquement)
          if (canComment)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ajouter un commentaire ou une remarque',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Écrivez vos remarques, suggestions ou recommandations...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _submitComment(indicator),
                      icon: const Icon(Icons.send),
                      label: const Text('Envoyer le commentaire'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                ],
              ),
            ),
          
          // Liste des commentaires
          _buildCommentsList(indicator),
        ],
      ),
    );
  }

  Widget _buildCommentsList(HSEIndicator indicator) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('comments')
          .where('documentId', isEqualTo: widget.indicatorId)
          .where('collectionName', isEqualTo: 'hseIndicators')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        final comments = snapshot.data?.docs ?? [];

        if (comments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Aucun commentaire pour le moment',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: comments.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final userName = data['userName'] ?? 'Utilisateur';
              final userRole = data['userRole'] ?? '';
              final comment = data['comment'] ?? '';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary.withOpacity(0.2),
                            child: Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  userRole,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (createdAt != null)
                            Text(
                              '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        comment,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _submitComment(HSEIndicator indicator) async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez écrire un commentaire'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Utilisateur non connecté');

      // Ajouter le commentaire
      await _firestore.collection('comments').add({
        'documentId': widget.indicatorId,
        'collectionName': 'hseIndicators',
        'projectId': widget.projectId,
        'userId': userId,
        'userName': _currentUserName ?? 'Utilisateur',
        'userRole': _userRole?.displayName ?? 'Utilisateur',
        'comment': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Créer une notification pour le consultant
      await _createNotificationForConsultant(indicator, userId);

      _commentController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commentaire envoyé avec succès'),
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
    }
  }

  Future<void> _createNotificationForConsultant(HSEIndicator indicator, String supervisorId) async {
    try {
      // Récupérer l'utilisateur qui a créé l'indicateur
      final indicatorDoc = await _firestore
          .collection('hseIndicators')
          .doc(widget.indicatorId)
          .get();
      
      final createdByUserId = indicatorDoc.data()?['userId'] ?? indicatorDoc.data()?['createdBy'];
      
      if (createdByUserId != null && createdByUserId != supervisorId) {
        await _firestore.collection('notifications').add({
          'userId': createdByUserId,
          'type': 'comment',
          'title': 'Nouveau commentaire sur votre indicateur HSE',
          'message': 'Un superviseur a laissé un commentaire sur votre indicateur HSE du mois ${indicator.mois}',
          'documentId': widget.indicatorId,
          'collectionName': 'hseIndicators',
          'projectId': widget.projectId,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
    } catch (e) {
      print('Erreur lors de la création de la notification: $e');
    }
  }
}

class HSEIndicatorEditScreen extends StatefulWidget {
  final String indicatorId;
  final String projectId;

  const HSEIndicatorEditScreen({
    super.key,
    required this.indicatorId,
    required this.projectId,
  });

  @override
  State<HSEIndicatorEditScreen> createState() => _HSEIndicatorEditScreenState();
}

class _HSEIndicatorEditScreenState extends State<HSEIndicatorEditScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  // Controllers
  late TextEditingController _responsableHSEController;
  late TextEditingController _zoneController;
  late TextEditingController _observationsController;
  
  String _selectedMonth = 'Janvier';
  DateTime? _selectedDate;
  
  // Indicateurs
  late Map<String, String> _environmentalIndicators;
  late Map<String, String> _socialIndicators;
  late Map<String, TextEditingController> _quantitativeIndicators;

  final List<String> _months = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  final List<String> _options = ['Oui', 'Non', 'Partiel', 'N.A'];

  final List<String> _quantitativeFields = [
    'Nombre de formations/sensibilisations',
    'Nombre d\'accidents',
    'Nombre de cas de maladie avec arrêt',
    'Nombre d\'inspections',
    'Nombre de non-conformités',
    'Nombre de plaintes et solutions',
    'Nombre d\'EPI distribués',
    'Nombre de visites médicales',
    'Nombre de jours sans accident',
    'Nombre de femmes employées',
    'Nombre d\'hommes employés',
    'Nombre total de personnes',
    'Nombre d\'expatriés',
    'Nombre de nationaux',
  ];

  @override
  void initState() {
    super.initState();
    _responsableHSEController = TextEditingController();
    _zoneController = TextEditingController();
    _observationsController = TextEditingController();
    _quantitativeIndicators = {};
    _environmentalIndicators = {};
    _socialIndicators = {};
    
    for (var field in _quantitativeFields) {
      _quantitativeIndicators[field] = TextEditingController();
    }
    
    _loadIndicatorData();
  }

  Future<void> _loadIndicatorData() async {
    try {
      final doc = await _firestore
          .collection('hseIndicators')
          .doc(widget.indicatorId)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _responsableHSEController.text = data['responsableHSE'] ?? '';
          _zoneController.text = data['zone'] ?? '';
          _selectedMonth = data['mois'] ?? 'Janvier';
          _observationsController.text = data['observations'] ?? '';
          
          if (data['dateSubmission'] != null) {
            _selectedDate = (data['dateSubmission'] as Timestamp).toDate();
          }
          
          _environmentalIndicators = Map<String, String>.from(data['environmentalIndicators'] ?? {});
          _socialIndicators = Map<String, String>.from(data['socialIndicators'] ?? {});
          
          final quantitative = data['quantitativeIndicators'] as Map<String, dynamic>? ?? {};
          for (var field in _quantitativeFields) {
            _quantitativeIndicators[field]!.text = (quantitative[field] ?? 0).toString();
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _firestore.collection('hseIndicators').doc(widget.indicatorId).update({
        'responsableHSE': _responsableHSEController.text,
        'zone': _zoneController.text,
        'mois': _selectedMonth,
        'dateSubmission': _selectedDate,
        'environmentalIndicators': _environmentalIndicators,
        'socialIndicators': _socialIndicators,
        'quantitativeIndicators': {
          for (var entry in _quantitativeIndicators.entries)
            entry.key: int.tryParse(entry.value.text) ?? 0
        },
        'observations': _observationsController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Indicateur modifié avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _responsableHSEController.dispose();
    _zoneController.dispose();
    _observationsController.dispose();
    for (var controller in _quantitativeIndicators.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Modifier Indicateur HSE'),
          backgroundColor: AppColors.primary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Modifier Indicateur HSE'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Section 1 : Informations Générales'),
              _buildTextField(
                controller: _responsableHSEController,
                label: 'Nom du responsable HSE',
                icon: Icons.person,
              ),
              const SizedBox(height: 12),
              _buildMonthDropdown(),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _zoneController,
                label: 'Zone ou site concerné',
                icon: Icons.location_on,
              ),
              const SizedBox(height: 12),
              _buildDatePicker(),
              const SizedBox(height: 24),

              _buildSectionHeader('Section 2 : Indicateurs Environnementaux'),
              ..._buildIndicatorsList(_environmentalIndicators),
              const SizedBox(height: 24),

              _buildSectionHeader('Section 3 : Indicateurs Sociaux et de Santé'),
              ..._buildIndicatorsList(_socialIndicators),
              const SizedBox(height: 24),

              _buildSectionHeader('Section 4 : Indicateurs Quantitatifs'),
              ..._buildQuantitativeFields(),
              const SizedBox(height: 24),

              _buildSectionHeader('Section 5 : Observations Complémentaires'),
              _buildTextAreaField(
                controller: _observationsController,
                label: 'Commentaires ou observations terrain',
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveChanges,
                  icon: const Icon(Icons.save),
                  label: const Text('Enregistrer les modifications'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF263238),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Ce champ est requis';
        return null;
      },
    );
  }

  Widget _buildTextAreaField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildMonthDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedMonth,
      decoration: InputDecoration(
        labelText: 'Mois de suivi',
        prefixIcon: const Icon(Icons.calendar_month, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      items: _months.map((month) {
        return DropdownMenuItem(value: month, child: Text(month));
      }).toList(),
      onChanged: (value) {
        if (value != null) setState(() => _selectedMonth = value);
      },
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              _selectedDate != null
                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                  : 'Date de soumission',
              style: TextStyle(
                color: _selectedDate != null ? Colors.black : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildIndicatorsList(Map<String, String> indicators) {
    return indicators.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _options.map((option) {
                  final isSelected = entry.value == option;
                  return ChoiceChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => indicators[entry.key] = option);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildQuantitativeFields() {
    return _quantitativeFields.map((field) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: _quantitativeIndicators[field],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: field,
            prefixIcon: const Icon(Icons.numbers, color: AppColors.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      );
    }).toList();
  }
}
