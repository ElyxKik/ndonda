import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/constants.dart';
import 'export_data_screen.dart';

class RapportScreen extends StatefulWidget {
  const RapportScreen({super.key});

  @override
  State<RapportScreen> createState() => _RapportScreenState();
}

class _RapportScreenState extends State<RapportScreen> {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  bool _isLoading = true;
  
  // Filtre
  String _selectedPeriod = 'Hebdomadaire';
  final List<String> _periods = ['Hebdomadaire', 'Mensuel', 'Trimestriel', 'Annuel'];
  
  // KPI Data
  int _totalProjets = 0;
  int _totalIncidents = 0;
  int _totalEquipements = 0;
  int _totalDechets = 0;
  int _totalSensibilisations = 0;
  int _totalContentieux = 0;
  int _totalPersonnel = 0;
  int _totalEvenements = 0;

  @override
  void initState() {
    super.initState();
    _loadKPIData();
  }

  Future<void> _loadKPIData() async {
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      // Charger tous les projets
      final projectsSnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .get();

      final projectIds = projectsSnapshot.docs.map((doc) => doc.id).toList();

      if (projectIds.isEmpty) {
        setState(() {
          _totalProjets = 0;
          _isLoading = false;
        });
        return;
      }

      // Charger les KPI pour chaque collection
      final futures = await Future.wait([
        _getCollectionCount('incidents', projectIds),
        _getCollectionCount('equipements', projectIds),
        _getCollectionCount('dechets', projectIds),
        _getCollectionCount('sensibilisations', projectIds),
        _getCollectionCount('contentieux', projectIds),
        _getCollectionCount('personnel', projectIds),
        _getCollectionCount('evenementChantier', projectIds),
      ]);

      if (mounted) {
        setState(() {
          _totalProjets = projectIds.length;
          _totalIncidents = futures[0];
          _totalEquipements = futures[1];
          _totalDechets = futures[2];
          _totalSensibilisations = futures[3];
          _totalContentieux = futures[4];
          _totalPersonnel = futures[5];
          _totalEvenements = futures[6];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des KPI: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<int> _getCollectionCount(String collection, List<String> projectIds) async {
    try {
      // Firestore limite les requêtes "in" à 10 éléments
      if (projectIds.length <= 10) {
        final snapshot = await FirebaseFirestore.instance
            .collection(collection)
            .where('projectId', whereIn: projectIds)
            .get();
        return snapshot.docs.length;
      } else {
        // Si plus de 10 projets, faire plusieurs requêtes
        int total = 0;
        for (int i = 0; i < projectIds.length; i += 10) {
          final batch = projectIds.skip(i).take(10).toList();
          final snapshot = await FirebaseFirestore.instance
              .collection(collection)
              .where('projectId', whereIn: batch)
              .get();
          total += snapshot.docs.length;
        }
        return total;
      }
    } catch (e) {
      print('Erreur pour $collection: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.eco,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ENVIROX',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Tableau de Bord',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadKPIData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 16),

                    // Filtres
                    _buildFiltersSection(),
                    const SizedBox(height: 24),

                    // KPI Cards
                    _buildKPISection(),
                    const SizedBox(height: 32),

                    // Bouton Télécharger
                    _buildDownloadButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vue d\'ensemble de vos projets et modules',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtres disponibles :',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _periods.map((period) {
              final isSelected = _selectedPeriod == period;
              return FilterChip(
                label: Text(period),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedPeriod = period;
                  });
                  // Reload data with new filter
                  _loadKPIData();
                },
                backgroundColor: Colors.grey.shade100,
                selectedColor: AppColors.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildKPISection() {
    final kpis = [
      {
        'title': 'Projets',
        'value': _totalProjets,
        'icon': Icons.folder,
        'color': AppColors.primary,
      },
      {
        'title': 'Incidents',
        'value': _totalIncidents,
        'icon': Icons.warning_amber_rounded,
        'color': Colors.red,
      },
      {
        'title': 'Équipements',
        'value': _totalEquipements,
        'icon': Icons.construction_rounded,
        'color': Colors.orange,
      },
      {
        'title': 'Déchets',
        'value': _totalDechets,
        'icon': Icons.delete_rounded,
        'color': Colors.brown,
      },
      {
        'title': 'Sensibilisations',
        'value': _totalSensibilisations,
        'icon': Icons.school_rounded,
        'color': Colors.green,
      },
      {
        'title': 'Contentieux',
        'value': _totalContentieux,
        'icon': Icons.gavel_rounded,
        'color': Colors.purple,
      },
      {
        'title': 'Personnel',
        'value': _totalPersonnel,
        'icon': Icons.groups_rounded,
        'color': Colors.teal,
      },
      {
        'title': 'Événements',
        'value': _totalEvenements,
        'icon': Icons.event_note,
        'color': Colors.indigo,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, index) {
        final kpi = kpis[index];
        return _buildKPICard(
          title: kpi['title'] as String,
          value: kpi['value'] as int,
          icon: kpi['icon'] as IconData,
          color: kpi['color'] as Color,
        );
      },
    );
  }

  Widget _buildKPICard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.download_rounded,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Télécharger les Données',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Exportez tous vos projets et modules au format Excel',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExportDataScreen(),
                ),
              );
            },
            icon: const Icon(Icons.file_download, size: 24),
            label: const Text(
              'Accéder aux Téléchargements',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
