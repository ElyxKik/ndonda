import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          widget.projectName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('projects').doc(widget.projectId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Projet non trouvé'),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          return _buildProjectDetails(data);
        },
      ),
    );
  }

  Widget _buildProjectDetails(Map<String, dynamic> data) {
    final nom = data['nom'] ?? 'Sans nom';
    final localisation = data['localisation'] ?? '';
    final maitreOuvrage = data['maitreOuvrage'] ?? '';
    final maitreOeuvre = data['maitreOeuvre'] ?? '';
    final maitreOuvrageDelegue = data['maitreOuvrageDelegue'] ?? '';
    final entreprises = data['entreprises'] ?? '';
    final specialisteSauvegarde = data['specialisteSauvegarde'] ?? '';
    final delaiTravaux = data['delaiTravaux'] ?? '';
    final montantFinancement = data['montantFinancement'] ?? '';
    
    // Conversion des dates (peut être String ou Timestamp)
    final dateDebut = _parseDate(data['dateDebut']);
    final dateFin = _parseDate(data['dateFin']);
    final dateApprobation = _parseDate(data['dateApprobation']);
    final createdAt = _parseDate(data['createdAt']);
    
    final budget = data['budget'] ?? 0.0;
    final description = data['description'] ?? '';
    final statut = data['statut'] ?? 'En cours';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec statut
          _buildHeader(nom, statut),
          
          const SizedBox(height: 16),
          
          // Informations principales
          _buildSection(
            title: 'Informations Générales',
            icon: Icons.info_outline,
            children: [
              _buildInfoRow('Nom du projet', nom, Icons.business),
              _buildInfoRow('Localisation', localisation, Icons.location_on),
              _buildInfoRow('Maître d\'ouvrage', maitreOuvrage, Icons.person_outline),
              _buildInfoRow('Maître d\'œuvre', maitreOeuvre, Icons.engineering),
              _buildInfoRow('Maître d\'ouvrage délégué', maitreOuvrageDelegue, Icons.supervised_user_circle),
              _buildInfoRow('Entreprise', entreprises, Icons.business_center),
              _buildInfoRow('Spécialiste sauvegarde', specialisteSauvegarde, Icons.security),
              _buildInfoRow('Statut', statut, Icons.flag, statusColor: _getStatusColor(statut)),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Dates
          _buildSection(
            title: 'Calendrier',
            icon: Icons.calendar_today,
            children: [
              if (dateDebut != null)
                _buildInfoRow(
                  'Date de début',
                  '${dateDebut.day}/${dateDebut.month}/${dateDebut.year}',
                  Icons.play_arrow,
                ),
              if (dateFin != null)
                _buildInfoRow(
                  'Date de fin',
                  '${dateFin.day}/${dateFin.month}/${dateFin.year}',
                  Icons.stop,
                ),
              if (dateApprobation != null)
                _buildInfoRow(
                  'Date d\'approbation',
                  '${dateApprobation.day}/${dateApprobation.month}/${dateApprobation.year}',
                  Icons.check_circle,
                ),
              if (dateDebut != null && dateFin != null)
                _buildInfoRow(
                  'Durée',
                  '${dateFin.difference(dateDebut).inDays} jours',
                  Icons.timelapse,
                ),
              if (delaiTravaux.isNotEmpty)
                _buildInfoRow(
                  'Délai des travaux',
                  delaiTravaux,
                  Icons.schedule,
                ),
              if (createdAt != null)
                _buildInfoRow(
                  'Créé le',
                  '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  Icons.add_circle_outline,
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Budget
          if (budget > 0 || montantFinancement.isNotEmpty)
            _buildSection(
              title: 'Budget',
              icon: Icons.attach_money,
              children: [
                if (budget > 0)
                  _buildInfoRow(
                    'Budget total',
                    '${budget.toStringAsFixed(0)} FCFA',
                    Icons.account_balance_wallet,
                  ),
                if (montantFinancement.isNotEmpty)
                  _buildInfoRow(
                    'Montant du financement',
                    montantFinancement,
                    Icons.monetization_on,
                  ),
              ],
            ),
          
          const SizedBox(height: 16),
          
          // Description
          if (description.isNotEmpty)
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
          
          // Statistiques du projet
          _buildStatistics(),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(String nom, String statut) {
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
              Expanded(
                child: Text(
                  nom,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(statut),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statut,
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

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? statusColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: statusColor ?? Colors.grey[600],
          ),
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

  Widget _buildStatistics() {
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
                Icon(Icons.bar_chart, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Statistiques',
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
          _buildStatisticsGrid(),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    final collections = [
      ('incidents', 'Incidents', Icons.warning_amber, Colors.orange),
      ('equipements', 'Equipements', Icons.build, Colors.blue),
      ('dechets', 'Dechets', Icons.delete, Colors.green),
      ('sensibilisations', 'Sensibilisation', Icons.campaign, Colors.purple),
      ('contentieux', 'Contentieux', Icons.gavel, Colors.red),
      ('evenementChantier', 'Evenements', Icons.event_note, Colors.indigo),
      ('personnel', 'Personnel', Icons.groups, Colors.teal),
      ('hseIndicators', 'Indicateurs HSE', Icons.assessment, Colors.deepOrange),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: collections.length,
        itemBuilder: (context, index) {
          final (collectionName, label, icon, color) = collections[index];
          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection(collectionName)
                .where('projectId', isEqualTo: widget.projectId)
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return _buildStatCard(label, count, icon, color);
            },
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'en cours':
        return Colors.blue;
      case 'terminé':
        return Colors.green;
      case 'en attente':
        return Colors.orange;
      case 'suspendu':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Convertir une date (String ou Timestamp) en DateTime
  DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    
    try {
      // Si c'est un Timestamp Firestore
      if (date is Timestamp) {
        return date.toDate();
      }
      // Si c'est une String
      if (date is String) {
        return DateTime.parse(date);
      }
      // Si c'est déjà un DateTime
      if (date is DateTime) {
        return date;
      }
      return null;
    } catch (e) {
      print('Erreur parsing date: $e');
      return null;
    }
  }
}
