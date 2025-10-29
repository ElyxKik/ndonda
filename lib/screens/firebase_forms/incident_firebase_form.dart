import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_service.dart';
import '../../services/image_service.dart';
import '../../utils/constants.dart';
import '../../widgets/photo_picker_widget.dart';

class IncidentFirebaseForm extends StatefulWidget {
  final String projectId;
  final String? incidentId;
  final Map<String, dynamic>? incidentData;

  const IncidentFirebaseForm({
    super.key,
    required this.projectId,
    this.incidentId,
    this.incidentData,
  });

  @override
  State<IncidentFirebaseForm> createState() => _IncidentFirebaseFormState();
}

class _IncidentFirebaseFormState extends State<IncidentFirebaseForm> {
  final _formKey = GlobalKey<FormState>();
  final _firebase = FirebaseService.instance;
  final _auth = AuthService.instance;
  final _imageService = ImageService.instance;

  // Controllers
  late TextEditingController _descriptionController;
  late TextEditingController _personneAffecteeController;
  late TextEditingController _fonctionController;
  late TextEditingController _mesuresPrisesController;
  late TextEditingController _joursArretController;
  late TextEditingController _localisationController;
  late TextEditingController _commentaireController;

  // State
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'accident_travail';
  String _selectedGravite = 'moyen';
  List<String> _photoUrls = [];
  List<String> _localPhotoPaths = [];
  bool _isLoading = false;
  bool _isUploading = false;

  // Options
  final List<Map<String, String>> _types = [
    {'value': 'maladie', 'label': 'Maladie'},
    {'value': 'accident_travail', 'label': 'Accident de travail'},
    {'value': 'accident_circulation', 'label': 'Accident de circulation'},
    {'value': 'autre', 'label': 'Autre'},
  ];

  final List<Map<String, dynamic>> _gravites = [
    {'value': 'leger', 'label': 'Léger', 'color': Colors.green},
    {'value': 'moyen', 'label': 'Moyen', 'color': Colors.orange},
    {'value': 'grave', 'label': 'Grave', 'color': Colors.red},
    {'value': 'mortel', 'label': 'Mortel', 'color': Colors.black},
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
    if (widget.incidentData != null) {
      _loadExistingData();
    }
  }

  void _initControllers() {
    _descriptionController = TextEditingController();
    _personneAffecteeController = TextEditingController();
    _fonctionController = TextEditingController();
    _mesuresPrisesController = TextEditingController();
    _joursArretController = TextEditingController(text: '0');
    _localisationController = TextEditingController();
    _commentaireController = TextEditingController();
  }

  void _loadExistingData() {
    final data = widget.incidentData!;
    _descriptionController.text = data['description'] ?? '';
    _personneAffecteeController.text = data['personneAffectee'] ?? '';
    _fonctionController.text = data['fonction'] ?? '';
    _mesuresPrisesController.text = data['mesuresPrises'] ?? '';
    _joursArretController.text = (data['joursArretTravail'] ?? 0).toString();
    _localisationController.text = data['localisation'] ?? '';
    _commentaireController.text = data['commentaire'] ?? '';
    
    if (data['date'] != null) {
      _selectedDate = DateTime.parse(data['date']);
    }
    _selectedType = data['type'] ?? 'accident_travail';
    _selectedGravite = data['gravite'] ?? 'moyen';
    
    if (data['photos'] != null && data['photos'] is List) {
      _photoUrls = List<String>.from(data['photos']);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _personneAffecteeController.dispose();
    _fonctionController.dispose();
    _mesuresPrisesController.dispose();
    _joursArretController.dispose();
    _localisationController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final paths = await _imageService.pickMultipleImages();
    if (paths != null && paths.isNotEmpty) {
      setState(() {
        _localPhotoPaths.addAll(paths);
      });
    }
  }

  Future<void> _uploadPhotos() async {
    if (_localPhotoPaths.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final incidentId = widget.incidentId ?? const Uuid().v4();
      final storagePath = 'incidents/${widget.projectId}/$incidentId';
      
      final urls = await _firebase.uploadFiles(_localPhotoPaths, storagePath);
      
      setState(() {
        _photoUrls.addAll(urls);
        _localPhotoPaths.clear();
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photos uploadées avec succès')),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur upload: $e')),
        );
      }
    }
  }

  Future<void> _saveIncident() async {
    if (!_formKey.currentState!.validate()) return;

    // Upload photos si nécessaire
    if (_localPhotoPaths.isNotEmpty) {
      await _uploadPhotos();
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final incidentId = widget.incidentId ?? const Uuid().v4();
      
      final data = {
        'projectId': widget.projectId,
        'date': _selectedDate.toIso8601String(),
        'type': _selectedType,
        'gravite': _selectedGravite,
        'description': _descriptionController.text.trim(),
        'personneAffectee': _personneAffecteeController.text.trim(),
        'fonction': _fonctionController.text.trim(),
        'mesuresPrises': _mesuresPrisesController.text.trim(),
        'joursArretTravail': int.tryParse(_joursArretController.text) ?? 0,
        'localisation': _localisationController.text.trim(),
        'photos': _photoUrls,
        'commentaire': _commentaireController.text.trim(),
        'updatedAt': now.toIso8601String(),
        'createdBy': _auth.currentUserId ?? 'anonymous',
      };

      if (widget.incidentId == null) {
        data['id'] = incidentId;
        data['createdAt'] = now.toIso8601String();
        await _firebase.setDocument('incidents', incidentId, data);
      } else {
        await _firebase.updateDocument('incidents', widget.incidentId!, data);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.incidentId == null 
              ? 'Incident enregistré avec succès' 
              : 'Incident mis à jour'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.incidentId == null 
          ? 'Nouvel Incident' 
          : 'Modifier Incident'),
        backgroundColor: AppColors.primary,
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
              onPressed: _saveIncident,
              tooltip: 'Enregistrer',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Date
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                title: const Text('Date de l\'incident'),
                subtitle: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Type d'incident
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Type d\'incident',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _types.map((type) {
                        final isSelected = _selectedType == type['value'];
                        return ChoiceChip(
                          label: Text(type['label']!),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedType = type['value']!);
                            }
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Gravité
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gravité',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _gravites.map((gravite) {
                        final isSelected = _selectedGravite == gravite['value'];
                        return ChoiceChip(
                          label: Text(gravite['label']!),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedGravite = gravite['value']!);
                            }
                          },
                          selectedColor: gravite['color'],
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description de l\'incident *',
                hintText: 'Décrivez l\'incident en détail',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La description est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Personne affectée
            TextFormField(
              controller: _personneAffecteeController,
              decoration: const InputDecoration(
                labelText: 'Personne affectée *',
                hintText: 'Nom de la personne',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Fonction
            TextFormField(
              controller: _fonctionController,
              decoration: const InputDecoration(
                labelText: 'Fonction',
                hintText: 'Fonction de la personne',
                prefixIcon: Icon(Icons.work),
              ),
            ),
            const SizedBox(height: 16),

            // Mesures prises
            TextFormField(
              controller: _mesuresPrisesController,
              decoration: const InputDecoration(
                labelText: 'Mesures prises *',
                hintText: 'Actions entreprises suite à l\'incident',
                prefixIcon: Icon(Icons.medical_services),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Les mesures prises sont obligatoires';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Jours d'arrêt
            TextFormField(
              controller: _joursArretController,
              decoration: const InputDecoration(
                labelText: 'Jours d\'arrêt de travail',
                hintText: '0',
                prefixIcon: Icon(Icons.event_busy),
                suffixText: 'jours',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (int.tryParse(value) == null) {
                    return 'Nombre invalide';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Localisation
            TextFormField(
              controller: _localisationController,
              decoration: const InputDecoration(
                labelText: 'Localisation',
                hintText: 'Lieu de l\'incident',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),

            // Commentaire
            TextFormField(
              controller: _commentaireController,
              decoration: const InputDecoration(
                labelText: 'Commentaire',
                hintText: 'Informations complémentaires',
                prefixIcon: Icon(Icons.comment),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Photos
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Photos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : _pickPhotos,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Ajouter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (_photoUrls.isNotEmpty || _localPhotoPaths.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._photoUrls.map((url) => _buildPhotoChip(url, true)),
                          ..._localPhotoPaths.map((path) => _buildPhotoChip(path, false)),
                        ],
                      ),
                    ],
                    if (_localPhotoPaths.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _isUploading ? null : _uploadPhotos,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.cloud_upload),
                        label: Text(_isUploading 
                          ? 'Upload en cours...' 
                          : 'Uploader les photos'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bouton Enregistrer
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveIncident,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Enregistrement...' : 'Enregistrer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoChip(String path, bool isUploaded) {
    return Chip(
      avatar: Icon(
        isUploaded ? Icons.cloud_done : Icons.image,
        color: isUploaded ? Colors.green : Colors.orange,
        size: 18,
      ),
      label: Text(
        path.split('/').last.length > 20
            ? '${path.split('/').last.substring(0, 20)}...'
            : path.split('/').last,
        style: const TextStyle(fontSize: 12),
      ),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: () {
        setState(() {
          if (isUploaded) {
            _photoUrls.remove(path);
          } else {
            _localPhotoPaths.remove(path);
          }
        });
      },
    );
  }
}
