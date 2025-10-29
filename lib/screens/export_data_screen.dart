import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/constants.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  bool _isLoading = false;
  String? _selectedProjectId;
  String? _selectedProjectName;
  List<Map<String, dynamic>> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('projects')
          .get();

      setState(() {
        _projects = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'nom': data['nom'] ?? 'Sans nom',
            'localisation': data['localisation'] ?? '',
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des projets: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportData(String collection, String collectionName) async {
    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un projet'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collection)
          .where('projectId', isEqualTo: _selectedProjectId)
          .get();

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Aucune donnée trouvée pour $collectionName'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // TODO: Implémenter l'export Excel ici
      // Pour l'instant, on affiche juste un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Export de ${snapshot.docs.length} enregistrements de $collectionName\n'
              'Fonctionnalité Excel à implémenter avec le package excel',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Télécharger les Données'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sélection du projet
                  _buildProjectSelector(),
                  const SizedBox(height: 32),

                  // Liste des modules à exporter
                  if (_selectedProjectId != null) ...[
                    const Text(
                      'Sélectionnez les données à exporter',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildExportModules(),
                  ] else
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Icon(
                            Icons.arrow_upward,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sélectionnez un projet pour commencer',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildProjectSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.folder,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Projet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_projects.isEmpty)
            const Text(
              'Aucun projet disponible',
              style: TextStyle(color: Colors.grey),
            )
          else
            DropdownButtonFormField<String>(
              value: _selectedProjectId,
              decoration: const InputDecoration(
                labelText: 'Sélectionner un projet',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              items: _projects.map((project) {
                return DropdownMenuItem<String>(
                  value: project['id'] as String,
                  child: Text(
                    project['nom'] as String,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProjectId = value;
                  _selectedProjectName = _projects
                      .firstWhere((p) => p['id'] == value)['nom'] as String;
                });
              },
            ),
          if (_selectedProjectName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Projet sélectionné: $_selectedProjectName',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExportModules() {
    final modules = [
      {
        'title': 'Incidents',
        'collection': 'incidents',
        'icon': Icons.warning_amber_rounded,
        'color': Colors.red,
      },
      {
        'title': 'Équipements',
        'collection': 'equipements',
        'icon': Icons.construction_rounded,
        'color': Colors.orange,
      },
      {
        'title': 'Déchets',
        'collection': 'dechets',
        'icon': Icons.delete_rounded,
        'color': Colors.brown,
      },
      {
        'title': 'Sensibilisations',
        'collection': 'sensibilisations',
        'icon': Icons.school_rounded,
        'color': Colors.green,
      },
      {
        'title': 'Contentieux',
        'collection': 'contentieux',
        'icon': Icons.gavel_rounded,
        'color': Colors.purple,
      },
      {
        'title': 'Personnel',
        'collection': 'personnelV2',
        'icon': Icons.groups_rounded,
        'color': Colors.teal,
      },
      {
        'title': 'Événements Chantier',
        'collection': 'evenementChantier',
        'icon': Icons.event_note,
        'color': Colors.indigo,
      },
    ];

    return Column(
      children: modules.map((module) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildExportCard(
            title: module['title'] as String,
            collection: module['collection'] as String,
            icon: module['icon'] as IconData,
            color: module['color'] as Color,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExportCard({
    required String title,
    required String collection,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Exporter au format Excel',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        trailing: ElevatedButton.icon(
          onPressed: () => _exportData(collection, title),
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Exporter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}
