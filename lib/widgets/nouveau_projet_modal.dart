import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../models/project.dart';

class NouveauProjetModal extends StatefulWidget {
  const NouveauProjetModal({super.key});

  @override
  State<NouveauProjetModal> createState() => _NouveauProjetModalState();
}

class _NouveauProjetModalState extends State<NouveauProjetModal> {
  final _formKey = GlobalKey<FormState>();
  final _firebase = FirebaseService.instance;
  final _auth = AuthService.instance;

  // Controllers
  late TextEditingController _nomController;
  late TextEditingController _localisationController;
  late TextEditingController _maitreOuvrageController;
  late TextEditingController _entrepriseController;
  late TextEditingController _consultantController;
  late TextEditingController _descriptionController;

  DateTime _dateDebut = DateTime.now();
  DateTime? _dateFin;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController();
    _localisationController = TextEditingController();
    _maitreOuvrageController = TextEditingController();
    _entrepriseController = TextEditingController();
    _consultantController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _localisationController.dispose();
    _maitreOuvrageController.dispose();
    _entrepriseController.dispose();
    _consultantController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final projectId = const Uuid().v4();
      
      final project = Project(
        id: projectId,
        nom: _nomController.text.trim(),
        localisation: _localisationController.text.trim(),
        maitreOuvrage: _maitreOuvrageController.text.trim(),
        entreprise: _entrepriseController.text.trim(),
        consultant: _consultantController.text.trim(),
        dateDebut: _dateDebut,
        dateFin: _dateFin,
        description: _descriptionController.text.trim(),
        createdAt: now,
        updatedAt: now,
        userId: _auth.currentUserId,
        archived: false,
      );

      await _firebase.setDocument('projects', projectId, project.toMap());

      if (mounted) {
        Navigator.pop(context, project);
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Nouveau Projet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Nom du projet
                    TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du projet *',
                        hintText: 'Ex: Projet Sécurité Aérienne',
                        prefixIcon: Icon(Icons.folder),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom est obligatoire';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Localisation
                    TextFormField(
                      controller: _localisationController,
                      decoration: const InputDecoration(
                        labelText: 'Localisation *',
                        hintText: 'Ex: Mbujumayi, Kasai-Oriental, RDC',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La localisation est obligatoire';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Maître d'ouvrage
                    TextFormField(
                      controller: _maitreOuvrageController,
                      decoration: const InputDecoration(
                        labelText: 'Maître d\'ouvrage *',
                        hintText: 'Ex: Gouvernement',
                        prefixIcon: Icon(Icons.account_balance),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le maître d\'ouvrage est obligatoire';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Entreprise
                    TextFormField(
                      controller: _entrepriseController,
                      decoration: const InputDecoration(
                        labelText: 'Entreprise *',
                        hintText: 'Ex: Entreprise ABC',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'L\'entreprise est obligatoire';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Consultant
                    TextFormField(
                      controller: _consultantController,
                      decoration: const InputDecoration(
                        labelText: 'Consultant *',
                        hintText: 'Ex: Jean Dupont',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le consultant est obligatoire';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date de début
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _dateDebut,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() => _dateDebut = date);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date de début *',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${_dateDebut.day}/${_dateDebut.month}/${_dateDebut.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date de fin (optionnelle)
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _dateFin ?? _dateDebut.add(const Duration(days: 365)),
                          firstDate: _dateDebut,
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() => _dateFin = date);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date de fin (optionnelle)',
                          prefixIcon: Icon(Icons.event),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _dateFin != null
                              ? '${_dateFin!.day}/${_dateFin!.month}/${_dateFin!.year}'
                              : 'Non définie',
                          style: TextStyle(
                            fontSize: 16,
                            color: _dateFin != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Description du projet',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Boutons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey[400]!),
                            ),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveProject,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Créer',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
