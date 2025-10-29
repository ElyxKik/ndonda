import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import 'project_detail_screen.dart';

class ProjetsScreen extends StatefulWidget {
  const ProjetsScreen({super.key});

  @override
  State<ProjetsScreen> createState() => _ProjetsScreenState();
}

class _ProjetsScreenState extends State<ProjetsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Mes Projets',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildProjectsList(),
          ),
        ],
      ),
      floatingActionButton: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final canManageProjects = provider.canPerformAction('manageProjects');
          
          if (!canManageProjects) {
            return const SizedBox.shrink(); // Masquer pour non-admins
          }
          
          return FloatingActionButton.extended(
            onPressed: () => _showAddProjectDialog(),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add),
            label: const Text('Nouveau Projet'),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Rechercher un projet...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildProjectsList() {
    final userId = _auth.currentUser?.uid;

    if (userId == null) {
      return const Center(
        child: Text('Utilisateur non connecté'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('projects')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
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
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        var projects = snapshot.data?.docs ?? [];

        // Filtrer les projets selon la recherche
        if (_searchQuery.isNotEmpty) {
          projects = projects.where((project) {
            final data = project.data() as Map<String, dynamic>;
            final nom = (data['nom'] ?? '').toString().toLowerCase();
            final localisation = (data['localisation'] ?? '').toString().toLowerCase();
            final maitreOuvrage = (data['maitreOuvrage'] ?? '').toString().toLowerCase();
            return nom.contains(_searchQuery) ||
                localisation.contains(_searchQuery) ||
                maitreOuvrage.contains(_searchQuery);
          }).toList();
        }

        if (projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun projet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Créez votre premier projet',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            final data = project.data() as Map<String, dynamic>;

            return _buildProjectCard(
              projectId: project.id,
              nom: data['nom'] ?? 'Sans nom',
              localisation: data['localisation'] ?? 'Non spécifié',
              maitreOuvrage: data['maitreOuvrage'] ?? '',
              entreprises: data['entreprises'] ?? '',
              createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
              dateDebut: (data['dateDebut'] as Timestamp?)?.toDate(),
            );
          },
        );
      },
    );
  }

  Widget _buildProjectCard({
    required String projectId,
    required String nom,
    required String localisation,
    required String maitreOuvrage,
    required String entreprises,
    DateTime? createdAt,
    DateTime? dateDebut,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailScreen(
                projectId: projectId,
                projectName: nom,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
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
                    if (dateDebut != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Début: ${dateDebut.day}/${dateDebut.month}/${dateDebut.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Consumer<AppProvider>(
                builder: (context, provider, child) {
                  final canManageProjects = provider.canPerformAction('manageProjects');
                  
                  if (!canManageProjects) {
                    return const SizedBox.shrink(); // Masquer pour non-admins
                  }
                  
                  return PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditProjectDialog(
                          projectId,
                          nom,
                          localisation,
                          maitreOuvrage,
                          entreprises,
                        );
                      } else if (value == 'delete') {
                        _confirmDeleteProject(projectId, nom);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddProjectDialog() {
    final nomController = TextEditingController();
    final localisationController = TextEditingController();
    final maitreOuvrageController = TextEditingController();
    final maitreOeuvreController = TextEditingController();
    final maitreOuvrageDelegueController = TextEditingController();
    final entreprisesController = TextEditingController();
    final specialisteSauvegardeController = TextEditingController();
    final delaiTravauxController = TextEditingController();
    final montantFinancementController = TextEditingController();
    DateTime? dateDebut;
    DateTime? dateApprobation;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nouveau Projet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom du projet *',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: localisationController,
                decoration: const InputDecoration(
                  labelText: 'Localisation *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maitreOuvrageController,
                decoration: const InputDecoration(
                  labelText: 'Maître d\'ouvrage',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maitreOeuvreController,
                decoration: const InputDecoration(
                  labelText: 'Maître d\'œuvre',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maitreOuvrageDelegueController,
                decoration: const InputDecoration(
                  labelText: 'Maître d\'ouvrage délégué',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: entreprisesController,
                decoration: const InputDecoration(
                  labelText: 'Entreprises',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: specialisteSauvegardeController,
                decoration: const InputDecoration(
                  labelText: 'Spécialiste sauvegarde',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: delaiTravauxController,
                decoration: const InputDecoration(
                  labelText: 'Délai des travaux',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: montantFinancementController,
                decoration: const InputDecoration(
                  labelText: 'Montant du financement',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              // Date de début
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: dateDebut ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      dateDebut = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date de début',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    dateDebut != null
                        ? '${dateDebut!.day}/${dateDebut!.month}/${dateDebut!.year}'
                        : 'Sélectionner une date',
                    style: TextStyle(
                      color: dateDebut != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Date d'approbation
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: dateApprobation ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      dateApprobation = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date d\'approbation',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    dateApprobation != null
                        ? '${dateApprobation!.day}/${dateApprobation!.month}/${dateApprobation!.year}'
                        : 'Sélectionner une date',
                    style: TextStyle(
                      color: dateApprobation != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomController.text.trim().isEmpty ||
                  localisationController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Veuillez remplir tous les champs obligatoires'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              await _createProject(
                nom: nomController.text.trim(),
                localisation: localisationController.text.trim(),
                maitreOuvrage: maitreOuvrageController.text.trim(),
                maitreOeuvre: maitreOeuvreController.text.trim(),
                maitreOuvrageDelegue:
                    maitreOuvrageDelegueController.text.trim(),
                entreprises: entreprisesController.text.trim(),
                specialisteSauvegarde:
                    specialisteSauvegardeController.text.trim(),
                delaiTravaux: delaiTravauxController.text.trim(),
                montantFinancement: montantFinancementController.text.trim(),
                dateDebut: dateDebut,
                dateApprobation: dateApprobation,
              );

              if (mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Créer'),
          ),
        ],
        ),
      ),
    );
  }

  void _showEditProjectDialog(
    String projectId,
    String currentNom,
    String currentLocalisation,
    String currentMaitreOuvrage,
    String currentEntreprises,
  ) {
    final nomController = TextEditingController(text: currentNom);
    final localisationController =
        TextEditingController(text: currentLocalisation);
    final maitreOuvrageController =
        TextEditingController(text: currentMaitreOuvrage);
    final entreprisesController =
        TextEditingController(text: currentEntreprises);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le Projet'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom du projet *',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: localisationController,
                decoration: const InputDecoration(
                  labelText: 'Localisation *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maitreOuvrageController,
                decoration: const InputDecoration(
                  labelText: 'Maître d\'ouvrage (optionnel)',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: entreprisesController,
                decoration: const InputDecoration(
                  labelText: 'Entreprises (optionnel)',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomController.text.trim().isEmpty ||
                  localisationController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Veuillez remplir tous les champs obligatoires'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              await _updateProject(
                projectId: projectId,
                nom: nomController.text.trim(),
                localisation: localisationController.text.trim(),
                maitreOuvrage: maitreOuvrageController.text.trim(),
                entreprises: entreprisesController.text.trim(),
              );

              if (mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProject(String projectId, String nom) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer le projet "$nom" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _deleteProject(projectId);
              if (mounted) {
                Navigator.pop(context);
              }
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

  Future<void> _createProject({
    required String nom,
    required String localisation,
    required String maitreOuvrage,
    required String maitreOeuvre,
    required String maitreOuvrageDelegue,
    required String entreprises,
    required String specialisteSauvegarde,
    required String delaiTravaux,
    required String montantFinancement,
    DateTime? dateDebut,
    DateTime? dateApprobation,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Utilisateur non connecté');

      final docRef = await _firestore.collection('projects').add({
        'nom': nom,
        'localisation': localisation,
        'maitreOuvrage': maitreOuvrage,
        'maitreOeuvre': maitreOeuvre,
        'maitreOuvrageDelegue': maitreOuvrageDelegue,
        'entreprises': entreprises,
        'specialisteSauvegarde': specialisteSauvegarde,
        'delaiTravaux': delaiTravaux,
        'montantFinancement': montantFinancement,
        'dateDebut': dateDebut != null
            ? Timestamp.fromDate(dateDebut)
            : FieldValue.serverTimestamp(),
        'dateApprobation': dateApprobation != null
            ? Timestamp.fromDate(dateApprobation)
            : FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'id': '', // Sera mis à jour juste après
        'userId': userId, // Ajout du champ userId pour les règles de sécurité
      });

      // Mettre à jour le champ 'id' avec l'ID du document
      await docRef.update({'id': docRef.id});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Projet créé avec succès'),
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

  Future<void> _updateProject({
    required String projectId,
    required String nom,
    required String localisation,
    required String maitreOuvrage,
    required String entreprises,
  }) async {
    try {
      await _firestore.collection('projects').doc(projectId).update({
        'nom': nom,
        'localisation': localisation,
        'maitreOuvrage': maitreOuvrage,
        'entreprises': entreprises,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Projet modifié avec succès'),
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

  Future<void> _deleteProject(String projectId) async {
    try {
      await _firestore.collection('projects').doc(projectId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Projet supprimé avec succès'),
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
}
