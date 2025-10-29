import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/plainte.dart';
import '../../services/database_service.dart';
import '../../services/image_service.dart';
import '../../utils/constants.dart';
import '../../widgets/photo_picker_widget.dart';

class PlainteFormScreen extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic>? plainte;

  const PlainteFormScreen({
    super.key,
    required this.projectId,
    this.plainte,
  });

  @override
  State<PlainteFormScreen> createState() => _PlainteFormScreenState();
}

class _PlainteFormScreenState extends State<PlainteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService.instance;
  final _imageService = ImageService.instance;

  late TextEditingController _plaignantController;
  late TextEditingController _contactController;
  late TextEditingController _objetController;
  late TextEditingController _descriptionController;
  late TextEditingController _actionMeneeController;
  late TextEditingController _commentaireController;
  
  DateTime _dateReception = DateTime.now();
  DateTime? _dateResolution;
  String _selectedCategorie = 'environnement';
  String _selectedPriorite = 'moyenne';
  String _selectedStatut = 'Enregistrée';
  String? _selectedSatisfaction;
  List<String> _photos = [];
  bool _isLoading = false;

  final List<String> _categories = [
    'environnement',
    'social',
    'bruit',
    'poussiere',
    'securite',
    'autre',
  ];

  final List<String> _priorites = [
    'faible',
    'moyenne',
    'haute',
    'urgente',
  ];

  final List<String> _satisfactions = [
    'satisfait',
    'partiellement_satisfait',
    'insatisfait',
  ];

  @override
  void initState() {
    super.initState();
    _plaignantController = TextEditingController();
    _contactController = TextEditingController();
    _objetController = TextEditingController();
    _descriptionController = TextEditingController();
    _actionMeneeController = TextEditingController();
    _commentaireController = TextEditingController();

    if (widget.plainte != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final data = widget.plainte!;
    _plaignantController.text = data['plaignant'] ?? '';
    _contactController.text = data['contact'] ?? '';
    _objetController.text = data['objet'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    _actionMeneeController.text = data['actionMenee'] ?? '';
    _commentaireController.text = data['commentaire'] ?? '';
    _dateReception = DateTime.parse(data['dateReception']);
    _dateResolution = data['dateResolution'] != null ? DateTime.parse(data['dateResolution']) : null;
    _selectedCategorie = data['categorie'] ?? 'environnement';
    _selectedPriorite = data['priorite'] ?? 'moyenne';
    _selectedStatut = data['statut'] ?? 'Enregistrée';
    _selectedSatisfaction = data['satisfaction'];
    
    if (data['photos'] != null && data['photos'].isNotEmpty) {
      _photos = data['photos'].split(',');
    }
  }

  @override
  void dispose() {
    _plaignantController.dispose();
    _contactController.dispose();
    _objetController.dispose();
    _descriptionController.dispose();
    _actionMeneeController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final path = await _imageService.pickImageFromCamera();
    if (path != null) {
      setState(() => _photos.add(path));
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _savePlainte() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final plainte = Plainte(
        id: widget.plainte?['id'] ?? const Uuid().v4(),
        projectId: widget.projectId,
        dateReception: _dateReception,
        plaignant: _plaignantController.text,
        contact: _contactController.text,
        objet: _objetController.text,
        description: _descriptionController.text,
        categorie: _selectedCategorie,
        priorite: _selectedPriorite,
        statut: _selectedStatut,
        actionMenee: _actionMeneeController.text.isEmpty ? null : _actionMeneeController.text,
        dateResolution: _dateResolution,
        satisfaction: _selectedSatisfaction,
        photos: _photos,
        commentaire: _commentaireController.text.isEmpty ? null : _commentaireController.text,
        createdAt: widget.plainte != null
            ? DateTime.parse(widget.plainte!['createdAt'])
            : DateTime.now(),
      );

      if (widget.plainte == null) {
        await _db.insert('plaintes', plainte.toMap());
      } else {
        await _db.update('plaintes', plainte.toMap(), plainte.id);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plainte enregistrée')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plainte == null ? 'Nouvelle Plainte' : 'Modifier Plainte'),
        backgroundColor: const Color(0xFF00796B),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _savePlainte,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date de réception
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                title: const Text('Date de réception'),
                subtitle: Text('${_dateReception.day}/${_dateReception.month}/${_dateReception.year}'),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateReception,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => _dateReception = date);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Plaignant
            TextFormField(
              controller: _plaignantController,
              decoration: const InputDecoration(
                labelText: 'Plaignant *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le nom du plaignant';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Contact
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: 'Contact *',
                prefixIcon: Icon(Icons.phone),
                hintText: 'Téléphone ou email',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le contact';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Catégorie
            DropdownButtonFormField<String>(
              value: _selectedCategorie,
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategorie = value!);
              },
            ),
            const SizedBox(height: 16),

            // Priorité
            DropdownButtonFormField<String>(
              value: _selectedPriorite,
              decoration: const InputDecoration(
                labelText: 'Priorité',
                prefixIcon: Icon(Icons.priority_high),
              ),
              items: _priorites.map((priorite) {
                return DropdownMenuItem(
                  value: priorite,
                  child: Text(priorite.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedPriorite = value!);
              },
            ),
            const SizedBox(height: 16),

            // Objet
            TextFormField(
              controller: _objetController,
              decoration: const InputDecoration(
                labelText: 'Objet de la plainte *',
                prefixIcon: Icon(Icons.subject),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer l\'objet';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Statut
            DropdownButtonFormField<String>(
              value: _selectedStatut,
              decoration: const InputDecoration(
                labelText: 'Statut',
                prefixIcon: Icon(Icons.flag),
              ),
              items: StatusOptions.plainteStatut.map((statut) {
                return DropdownMenuItem(
                  value: statut,
                  child: Text(statut),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedStatut = value!);
              },
            ),
            const SizedBox(height: 16),

            // Action menée
            TextFormField(
              controller: _actionMeneeController,
              decoration: const InputDecoration(
                labelText: 'Action menée',
                prefixIcon: Icon(Icons.build),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Date de résolution
            Card(
              child: ListTile(
                leading: const Icon(Icons.event_available, color: AppColors.primary),
                title: const Text('Date de résolution'),
                subtitle: Text(_dateResolution != null
                    ? '${_dateResolution!.day}/${_dateResolution!.month}/${_dateResolution!.year}'
                    : 'Non résolue'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_dateResolution != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _dateResolution = null);
                        },
                      ),
                    const Icon(Icons.edit),
                  ],
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateResolution ?? DateTime.now(),
                    firstDate: _dateReception,
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => _dateResolution = date);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Satisfaction
            DropdownButtonFormField<String?>(
              value: _selectedSatisfaction,
              decoration: const InputDecoration(
                labelText: 'Niveau de satisfaction',
                prefixIcon: Icon(Icons.sentiment_satisfied),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Non évalué'),
                ),
                ..._satisfactions.map((satisfaction) {
                  return DropdownMenuItem<String?>(
                    value: satisfaction,
                    child: Text(satisfaction.toUpperCase().replaceAll('_', ' ')),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _selectedSatisfaction = value);
              },
            ),
            const SizedBox(height: 16),

            // Photos
            PhotoPickerWidget(
              photos: _photos,
              onAddPhoto: _addPhoto,
              onRemovePhoto: _removePhoto,
            ),
            const SizedBox(height: 16),

            // Commentaire
            TextFormField(
              controller: _commentaireController,
              decoration: const InputDecoration(
                labelText: 'Commentaire',
                prefixIcon: Icon(Icons.comment),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _savePlainte,
                icon: const Icon(Icons.save),
                label: Text(widget.plainte == null ? 'Enregistrer' : 'Mettre à jour'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
