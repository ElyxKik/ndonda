import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class IncidentDetailScreen extends StatefulWidget {
  final String incidentId;
  final String projectId;

  const IncidentDetailScreen({
    super.key,
    required this.incidentId,
    required this.projectId,
  });

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Détails Incident'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('incidents')
            .doc(widget.incidentId)
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
              child: Text('Incident non trouvé'),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          return _buildIncidentDetails(data);
        },
      ),
    );
  }

  Widget _buildIncidentDetails(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final gravite = data['gravite'] ?? '';
    final date = data['date'] != null ? DateTime.parse(data['date']) : DateTime.now();
    final personneAffectee = data['personneAffectee'] ?? '';
    final fonction = data['fonction'] ?? '';
    final description = data['description'] ?? '';
    final mesuresPrises = data['mesuresPrises'] ?? '';
    final joursArretTravail = data['joursArretTravail'] ?? 0;
    final localisation = data['localisation'] ?? '';
    final commentaire = data['commentaire'] ?? '';
    final photos = data['photos'] is List ? List<String>.from(data['photos']) : [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          _buildHeader(type, gravite, date),
          
          const SizedBox(height: 16),
          
          // Informations générales
          _buildSection(
            title: 'Informations Générales',
            icon: Icons.info_outline,
            children: [
              _buildInfoRow('Type d\'incident', _getTypeLabel(type), Icons.category),
              _buildInfoRow('Gravité', _getGraviteLabel(gravite), Icons.warning),
              _buildInfoRow('Date', '${date.day}/${date.month}/${date.year}', Icons.calendar_today),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Personne affectée
          _buildSection(
            title: 'Personne Affectée',
            icon: Icons.person,
            children: [
              _buildInfoRow('Nom', personneAffectee, Icons.person_outline),
              if (fonction.isNotEmpty)
                _buildInfoRow('Fonction', fonction, Icons.work),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Description
          _buildSection(
            title: 'Description',
            icon: Icons.description,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  description,
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
          
          // Mesures prises
          _buildSection(
            title: 'Mesures Prises',
            icon: Icons.medical_services,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  mesuresPrises,
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
          
          // Informations supplémentaires
          _buildSection(
            title: 'Informations Supplémentaires',
            icon: Icons.info,
            children: [
              _buildInfoRow('Jours d\'arrêt', '$joursArretTravail jours', Icons.event_busy),
              if (localisation.isNotEmpty)
                _buildInfoRow('Localisation', localisation, Icons.location_on),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Commentaire
          if (commentaire.isNotEmpty)
            _buildSection(
              title: 'Commentaire',
              icon: Icons.comment,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    commentaire,
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
          
          // Photos
          if (photos.isNotEmpty)
            _buildSection(
              title: 'Photos',
              icon: Icons.photo,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          photos[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(String type, String gravite, DateTime date) {
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
              const Icon(Icons.warning_amber, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTypeLabel(type),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getGraviteColor(gravite),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getGraviteLabel(gravite),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'maladie':
        return 'Maladie';
      case 'accident_travail':
        return 'Accident de travail';
      case 'accident_circulation':
        return 'Accident de circulation';
      case 'autre':
        return 'Autre';
      default:
        return type;
    }
  }

  String _getGraviteLabel(String gravite) {
    switch (gravite.toLowerCase()) {
      case 'leger':
        return 'Léger';
      case 'moyen':
        return 'Moyen';
      case 'grave':
        return 'Grave';
      case 'mortel':
        return 'Mortel';
      default:
        return gravite;
    }
  }

  Color _getGraviteColor(String gravite) {
    switch (gravite.toLowerCase()) {
      case 'leger':
        return Colors.green;
      case 'moyen':
        return Colors.orange;
      case 'grave':
        return Colors.red;
      case 'mortel':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }
}
