import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/constants.dart';
import 'firebase_forms/audit_firebase_form.dart';

class AuditDetailScreen extends StatefulWidget {
  final String auditId;
  final String projectId;

  const AuditDetailScreen({
    super.key,
    required this.auditId,
    required this.projectId,
  });

  @override
  State<AuditDetailScreen> createState() => _AuditDetailScreenState();
}

class _AuditDetailScreenState extends State<AuditDetailScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Détails Audit'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('audit')
            .doc(widget.auditId)
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
              child: Text('Audit non trouvé'),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          return _buildAuditDetails(data);
        },
      ),
    );
  }

  Widget _buildAuditDetails(Map<String, dynamic> data) {
    final statut = data['statut'] ?? 'N/A';
    final responsable = data['responsableHSE'] ?? 'N/A';
    final mois = data['mois'] ?? 'N/A';
    final zone = data['zone'] ?? 'N/A';
    final observations = data['observations'] ?? '';
    final dateSubmission = data['dateSubmission'] as Timestamp?;
    
    final envIndicators = data['environmentalIndicators'] as Map<String, dynamic>? ?? {};
    final socialIndicators = data['socialIndicators'] as Map<String, dynamic>? ?? {};
    final quantIndicators = data['quantitativeIndicators'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          _buildHeader(statut, mois, zone),
          
          const SizedBox(height: 16),
          
          // Informations générales
          _buildSection(
            title: 'Informations Générales',
            icon: Icons.info_outline,
            children: [
              _buildInfoRow('Responsable HSE', responsable, Icons.person),
              _buildInfoRow('Mois', mois, Icons.calendar_month),
              _buildInfoRow('Zone', zone, Icons.location_on),
              _buildInfoRow('Statut', statut.toUpperCase(), Icons.flag, 
                color: _getStatutColor(statut)),
              if (dateSubmission != null)
                _buildInfoRow(
                  'Date de soumission',
                  '${dateSubmission.toDate().day}/${dateSubmission.toDate().month}/${dateSubmission.toDate().year}',
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
              _buildIndicatorsList(envIndicators),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Indicateurs sociaux
          _buildSection(
            title: 'Indicateurs Sociaux et de Santé',
            icon: Icons.people,
            children: [
              _buildIndicatorsList(socialIndicators),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Indicateurs quantitatifs
          _buildSection(
            title: 'Indicateurs Quantitatifs',
            icon: Icons.bar_chart,
            children: [
              _buildQuantitativeIndicators(quantIndicators),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Observations
          if (observations.isNotEmpty)
            _buildSection(
              title: 'Observations Complémentaires',
              icon: Icons.comment,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    observations,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(String statut, String mois, String zone) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getStatutColor(statut), _getStatutColor(statut).withOpacity(0.8)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fact_check, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audit ${statut.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$mois - $zone',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
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
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color ?? const Color(0xFF263238),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorsList(Map<String, dynamic> indicators) {
    if (indicators.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Aucun indicateur'),
      );
    }

    return Column(
      children: indicators.entries.map((entry) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getIndicatorColor(entry.value.toString()).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getIndicatorColor(entry.value.toString()).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getIndicatorIcon(entry.value.toString()),
                color: _getIndicatorColor(entry.value.toString()),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getIndicatorColor(entry.value.toString()),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.value.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuantitativeIndicators(Map<String, dynamic> indicators) {
    if (indicators.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Aucun indicateur quantitatif'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: indicators.entries.map((entry) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.value.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.key,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF263238),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getStatutColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'interne':
        return Colors.blue;
      case 'externe':
        return Colors.purple;
      case 'supervision':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  Color _getIndicatorColor(String value) {
    switch (value) {
      case 'Oui':
        return Colors.green;
      case 'Non':
        return Colors.red;
      case 'Partiel':
        return Colors.orange;
      case 'N.A':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getIndicatorIcon(String value) {
    switch (value) {
      case 'Oui':
        return Icons.check_circle;
      case 'Non':
        return Icons.cancel;
      case 'Partiel':
        return Icons.warning;
      case 'N.A':
        return Icons.help_outline;
      default:
        return Icons.help_outline;
    }
  }
}
