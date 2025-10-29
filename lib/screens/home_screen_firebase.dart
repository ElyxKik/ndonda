import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../widgets/app_logo.dart';
import 'compte_screen.dart';
import 'projets_screen.dart';
import 'project_selector_screen.dart';
import 'rapport_screen.dart';
import 'users_management_screen.dart';
import 'firebase_forms/incident_firebase_form.dart';
import 'firebase_forms/equipement_firebase_form.dart';
import 'firebase_forms/dechet_firebase_form.dart';
import 'firebase_forms/sensibilisation_firebase_form.dart';
import 'firebase_forms/contentieux_firebase_form.dart';
import 'firebase_forms/evenement_chantier_firebase_form.dart';
import 'firebase_forms/personnel_firebase_form.dart';
import 'reports/photo_report_screen.dart';
import 'reports/activity_report_screen.dart';
import 'reports/supervision_report_screen.dart';
import 'reports/consultant_report_screen.dart';

class HomeScreenFirebase extends StatefulWidget {
  const HomeScreenFirebase({super.key});

  @override
  State<HomeScreenFirebase> createState() => _HomeScreenFirebaseState();
}

class _HomeScreenFirebaseState extends State<HomeScreenFirebase> {
  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      await provider.loadUserRole(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildHeader(context, provider),
              Expanded(
                child: _buildContent(context, provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Logo ENVIROX
              const AppLogoCompact(size: 40),
              const SizedBox(width: 12),
              // Titre
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ENVIROX',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    'Gestion Environnementale',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Menu déroulant
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.menu,
                  color: Colors.white,
                  size: 28,
                ),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                offset: const Offset(0, 50),
                onSelected: (value) {
                  if (value == 'accueil') {
                    // Déjà sur l'accueil
                  } else if (value == 'rapport') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RapportScreen(),
                      ),
                    );
                  } else if (value == 'compte') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CompteScreen(),
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) {
                  final canViewReports = provider.canPerformAction('viewReports');
                  
                  return [
                    PopupMenuItem<String>(
                      value: 'accueil',
                      child: Row(
                        children: [
                          Icon(
                            Icons.home_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Accueil',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (canViewReports)
                      PopupMenuItem<String>(
                        value: 'rapport',
                        child: Row(
                          children: [
                            Icon(
                              Icons.assessment_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Rapport',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    PopupMenuItem<String>(
                      value: 'compte',
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_circle_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        const SizedBox(width: 12),
                        const Text(
                          'Compte',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppProvider provider) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Projet
            _buildProjectSection(context),
            const SizedBox(height: 24),
            
            // Section Actions Rapides
            _buildQuickActionsSection(context, provider),
            const SizedBox(height: 24),
            
            // Section Modules PGES
            _buildModulesSection(context, provider),
            const SizedBox(height: 24),
            
            // Section Rapports
            _buildReportsSection(context, provider),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectSection(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Projet actuel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProjetsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Voir tous'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('projects')
              .orderBy('createdAt', descending: true)
              .limit(1)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorProjectCard(snapshot.error.toString());
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingProjectCard();
            }

            final projects = snapshot.data?.docs ?? [];

            if (projects.isEmpty) {
              return _buildEmptyProjectCard(context);
            }

            final project = projects.first;
            final data = project.data() as Map<String, dynamic>;

            return _buildCurrentProjectCard(
              context,
              projectId: project.id,
              nom: data['nom'] ?? 'Sans nom',
              localisation: data['localisation'] ?? 'Non spécifié',
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyProjectCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_open,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun projet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre premier projet pour commencer',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProjetsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Créer un projet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentProjectCard(
    BuildContext context, {
    required String projectId,
    required String nom,
    required String localisation,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProjetsScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
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
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.folder,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nom,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          localisation,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingProjectCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorProjectCard(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, AppProvider provider) {
    final canViewReports = provider.canPerformAction('viewReports');
    final canManageUsers = provider.canPerformAction('manageUsers');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF263238),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                title: 'Projets',
                icon: Icons.folder_rounded,
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProjetsScreen(),
                    ),
                  );
                },
              ),
            ),
            if (canViewReports) ...[
              const SizedBox(width: 14),
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  title: 'Rapports',
                  icon: Icons.bar_chart_rounded,
                  color: const Color(0xFF0288D1),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RapportScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
        if (canManageUsers) ...[
          const SizedBox(height: 14),
          _buildQuickActionCard(
            context,
            title: 'Utilisateurs',
            icon: Icons.people_rounded,
            color: const Color(0xFF9C27B0),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UsersManagementScreen(),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesSection(BuildContext context, AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Modules PGES',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 22),
              onPressed: () {
                // Refresh action
              },
              tooltip: 'Actualiser',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildModulesGrid(context),
      ],
    );
  }

  Widget _buildModulesGrid(BuildContext context) {
    final modules = [
      {
        'title': 'Incidents',
        'subtitle': 'Accidents & Maladies',
        'icon': Icons.warning_amber_rounded,
        'color': Colors.red,
        'collection': 'incidents',
        'formBuilder': (String pid, {String? documentId, Map<String, dynamic>? data}) =>
            IncidentFirebaseForm(
              projectId: pid,
              incidentId: documentId,
              incidentData: data,
            ),
      },
      {
        'title': 'Équipements',
        'subtitle': 'EPI & EPC',
        'icon': Icons.construction_rounded,
        'color': Colors.orange,
        'collection': 'equipements',
        'formBuilder': (String pid, {String? documentId, Map<String, dynamic>? data}) =>
            EquipementFirebaseForm(
              projectId: pid,
              equipementId: documentId,
              equipementData: data,
            ),
      },
      {
        'title': 'Déchets',
        'subtitle': 'Gestion des déchets',
        'icon': Icons.delete_rounded,
        'color': Colors.brown,
        'collection': 'dechets',
        'formBuilder': (String pid, {String? documentId, Map<String, dynamic>? data}) =>
            DechetFirebaseForm(
              projectId: pid,
              dechetId: documentId,
              dechetData: data,
            ),
      },
      {
        'title': 'Sensibilisations',
        'subtitle': 'Formations & Causeries',
        'icon': Icons.people_rounded,
        'color': Colors.blue,
        'collection': 'sensibilisations',
        'formBuilder': (String pid, {String? documentId, Map<String, dynamic>? data}) =>
            SensibilisationFirebaseForm(
              projectId: pid,
              sensibilisationId: documentId,
              sensibilisationData: data,
            ),
      },
      {
        'title': 'Contentieux',
        'subtitle': 'Litiges & Résolutions',
        'icon': Icons.gavel_rounded,
        'color': Colors.purple,
        'collection': 'contentieux',
        'formBuilder': (String pid, {String? documentId, Map<String, dynamic>? data}) =>
            ContentieuxFirebaseForm(
              projectId: pid,
              contentieuxId: documentId,
              contentieuxData: data,
            ),
      },
      {
        'title': 'Personnel',
        'subtitle': 'Relevé détaillé',
        'icon': Icons.groups_rounded,
        'color': Colors.teal,
        'collection': 'personnel',
        'formBuilder': (String pid, {String? documentId, Map<String, dynamic>? data}) =>
            PersonnelFirebaseForm(
              projectId: pid,
              personnelId: documentId,
              personnelData: data,
            ),
      },
      {
        'title': 'Événement Chantier',
        'subtitle': 'Suivi des événements',
        'icon': Icons.event_note,
        'color': Colors.indigo,
        'collection': 'evenementChantier',
        'formBuilder': (String pid, {String? documentId, Map<String, dynamic>? data}) =>
            EvenementChantierFirebaseForm(
              projectId: pid,
              evenementId: documentId,
              evenementData: data,
            ),
      },
      {
        'title': 'Indicateur HSE',
        'subtitle': 'Performance HSE',
        'icon': Icons.assessment_rounded,
        'color': Colors.deepOrange,
        'isHSE': true,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.1,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        final isHSE = module['isHSE'] as bool? ?? false;
        
        return _buildModuleCard(
          context,
          title: module['title'] as String,
          subtitle: module['subtitle'] as String,
          icon: module['icon'] as IconData,
          color: module['color'] as Color,
          onTap: () {
            if (isHSE) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectSelectorScreen(
                    moduleTitle: 'Indicateur HSE',
                    collectionName: 'hseIndicators',
                    moduleIcon: Icons.assessment_rounded,
                    moduleColor: Colors.deepOrange,
                    isHSE: true,
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectSelectorScreen(
                    moduleTitle: module['title'] as String,
                    collectionName: module['collection'] as String,
                    moduleIcon: module['icon'] as IconData,
                    moduleColor: module['color'] as Color,
                    formBuilder: module['formBuilder'] as Widget Function(String, {String? documentId, Map<String, dynamic>? data}),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsSection(BuildContext context, AppProvider provider) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Rapports',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 22),
              onPressed: () {},
              tooltip: 'Actualiser',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildReportsGrid(context),
      ],
    );
  }

  Widget _buildReportsGrid(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    // Récupérer le projet actuel
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final projectId = snapshot.data!.docs.first.id;
        final projectName = (snapshot.data!.docs.first.data() as Map<String, dynamic>)['nom'] ?? 'Projet';

        final reports = [
          {
            'title': 'Rapport Photo',
            'subtitle': 'Bibliothèque d\'images',
            'icon': Icons.photo_library_rounded,
            'color': Colors.green,
            'screen': PhotoReportScreen(
              projectId: projectId,
              projectName: projectName,
            ),
          },
          {
            'title': 'Rapport d\'Activité',
            'subtitle': 'Activités réalisées',
            'icon': Icons.assignment_rounded,
            'color': Colors.blue,
            'screen': ActivityReportScreen(
              projectId: projectId,
              projectName: projectName,
            ),
          },
          {
            'title': 'Rapport de Supervision',
            'subtitle': 'Visites & Conformité',
            'icon': Icons.supervised_user_circle_rounded,
            'color': Colors.orange,
            'screen': SupervisionReportScreen(
              projectId: projectId,
              projectName: projectName,
            ),
          },
          {
            'title': 'Rapport de Consultant',
            'subtitle': 'Expertise & Analyse',
            'icon': Icons.business_center_rounded,
            'color': Colors.purple,
            'screen': ConsultantReportScreen(
              projectId: projectId,
              projectName: projectName,
            ),
          },
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.1,
          ),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return _buildReportCard(
              context,
              title: report['title'] as String,
              subtitle: report['subtitle'] as String,
              icon: report['icon'] as IconData,
              color: report['color'] as Color,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => report['screen'] as Widget,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
