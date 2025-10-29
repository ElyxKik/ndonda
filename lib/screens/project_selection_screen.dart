import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../models/project.dart';
import '../utils/date_utils.dart';
import '../widgets/app_header.dart';
import '../widgets/modern_card.dart';

class ProjectSelectionScreen extends StatefulWidget {
  const ProjectSelectionScreen({super.key});

  @override
  State<ProjectSelectionScreen> createState() => _ProjectSelectionScreenState();
}

class _ProjectSelectionScreenState extends State<ProjectSelectionScreen> {
  bool _isCreatingNew = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const AppHeaderWithBack(
            title: 'Projets',
            subtitle: 'Sélectionnez ou créez un projet',
          ),
          Expanded(
            child: Consumer<AppProvider>(
              builder: (context, provider, child) {
                if (_isCreatingNew) {
                  return _buildCreateProjectForm(provider);
                }

                return Column(
                  children: [
                    Expanded(
                      child: provider.projects.isEmpty
                          ? EmptyState(
                              icon: Icons.folder_off,
                              title: 'Aucun projet disponible',
                              subtitle: 'Créez votre premier projet\npour commencer',
                              buttonLabel: 'Créer un projet',
                              onButtonPressed: () {
                                setState(() {
                                  _isCreatingNew = true;
                                });
                              },
                            )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: provider.projects.length,
                        itemBuilder: (context, index) {
                          final project = provider.projects[index];
                          final isSelected = provider.currentProject?.id == project.id;

                          return ModernCard(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(18),
                            onTap: () {
                              provider.setCurrentProject(project);
                              Navigator.pop(context);
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF0288D1).withValues(alpha: 0.15)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.folder,
                                    color: isSelected
                                        ? const Color(0xFF0288D1)
                                        : Colors.grey.shade600,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        project.nom,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                          color: const Color(0xFF263238),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        project.localisation,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Début: ${AppDateUtils.formatDate(project.dateDebut)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0288D1).withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Color(0xFF0288D1),
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ModernButton(
                          label: 'Créer un nouveau projet',
                          icon: Icons.add,
                          onPressed: () {
                            setState(() {
                              _isCreatingNew = true;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateProjectForm(AppProvider provider) {
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController();
    final localisationController = TextEditingController();
    final maitreOuvrageController = TextEditingController();
    final entrepriseController = TextEditingController();
    final consultantController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime dateDebut = DateTime.now();
    DateTime? dateFin;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF37474F)),
                  onPressed: () {
                    setState(() {
                      _isCreatingNew = false;
                    });
                  },
                ),
                const Text(
                  'Nouveau Projet',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ModernTextField(
              label: 'Nom du projet *',
              controller: nomController,
              prefixIcon: Icons.title,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le nom du projet';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ModernTextField(
              label: 'Localisation *',
              controller: localisationController,
              prefixIcon: Icons.location_on,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer la localisation';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ModernTextField(
              label: 'Maître d\'ouvrage *',
              controller: maitreOuvrageController,
              prefixIcon: Icons.business,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le maître d\'ouvrage';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ModernTextField(
              label: 'Entreprise *',
              controller: entrepriseController,
              prefixIcon: Icons.apartment,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer l\'entreprise';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ModernTextField(
              label: 'Consultant *',
              controller: consultantController,
              prefixIcon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le consultant';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ModernTextField(
              label: 'Description',
              controller: descriptionController,
              prefixIcon: Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ModernButton(
                label: 'Créer le projet',
                icon: Icons.check,
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final project = Project(
                      id: const Uuid().v4(),
                      nom: nomController.text,
                      localisation: localisationController.text,
                      maitreOuvrage: maitreOuvrageController.text,
                      entreprise: entrepriseController.text,
                      consultant: consultantController.text,
                      dateDebut: dateDebut,
                      dateFin: dateFin,
                      description: descriptionController.text,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    await provider.createProject(project);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
