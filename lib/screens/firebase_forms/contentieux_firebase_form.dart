import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_service.dart';
import '../../services/image_service.dart';
import '../../utils/constants.dart';

class ContentieuxFirebaseForm extends StatefulWidget {
  final String projectId;
  final String? contentieuxId;
  final Map<String, dynamic>? contentieuxData;

  const ContentieuxFirebaseForm({
    super.key,
    required this.projectId,
    this.contentieuxId,
    this.contentieuxData,
  });

  @override
  State<ContentieuxFirebaseForm> createState() => _ContentieuxFirebaseFormState();
}

class _ContentieuxFirebaseFormState extends State<ContentieuxFirebaseForm> {
  final _formKey = GlobalKey<FormState>();
  final _firebase = FirebaseService.instance;
  final _auth = AuthService.instance;
  final _imageService = ImageService.instance;

  // Controllers
  late TextEditingController _objetController;
  late TextEditingController _partiesController;
  late TextEditingController _decisionController;
  late TextEditingController _commentaireController;

  // State
  DateTime _dateOuverture = DateTime.now();
  DateTime? _dateResolution;
  String _selectedNature = 'foncier';
  String _selectedStatut = 'Ouvert';
  String? _selectedModeResolution;
  List<String> _photoUrls = [];
  List<String> _localPhotoPaths = [];
  bool _isLoading = false;
  bool _isUploading = false;

  // Options
  final List<Map<String, dynamic>> _natures = [
    {'value': 'foncier', 'label': 'Foncier', 'icon': Icons.landscape, 'color': Colors.brown},
    {'value': 'commercial', 'label': 'Commercial', 'icon': Icons.business, 'color': Colors.blue},
    {'value': 'social', 'label': 'Social', 'icon': Icons.people, 'color': Colors.green},
    {'value': 'environnemental', 'label': 'Environnemental', 'icon': Icons.eco, 'color': Colors.green[700]},
    {'value': 'autre', 'label': 'Autre', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  final List<Map<String, dynamic>> _statuts = [
    {'value': 'Ouvert', 'label': 'Ouvert', 'color': Colors.orange},
    {'value': 'En cours', 'label': 'En cours', 'color': Colors.blue},
    {'value': 'Résolu', 'label': 'Résolu', 'color': Colors.green},
    {'value': 'Fermé', 'label': 'Fermé', 'color': Colors.grey},
  ];

  final List<Map<String, String>> _modesResolution = [
    {'value': 'amiable', 'label': 'Amiable'},
    {'value': 'mediation', 'label': 'Médiation'},
    {'value': 'arbitrage', 'label': 'Arbitrage'},
    {'value': 'judiciaire', 'label': 'Judiciaire'},
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
    if (widget.contentieuxData != null) {
      _loadExistingData();
    }
  }

  void _initControllers() {
    _objetController = TextEditingController();
    _partiesController = TextEditingController();
    _decisionController = TextEditingController();
    _commentaireController = TextEditingController();
  }

  void _loadExistingData() {
    final data = widget.contentieuxData!;
    _objetController.text = data['objet'] ?? '';
    _partiesController.text = data['parties'] ?? '';
    _decisionController.text = data['decision'] ?? '';
    _commentaireController.text = data['commentaire'] ?? '';
    
    if (data['dateOuverture'] != null) {
      _dateOuverture = DateTime.parse(data['dateOuverture']);
    }
    if (data['dateResolution'] != null) {
      _dateResolution = DateTime.parse(data['dateResolution']);
    }
    _selectedNature = data['nature'] ?? 'foncier';
    _selectedStatut = data['statut'] ?? 'Ouvert';
    _selectedModeResolution = data['modeResolution'];
    
    if (data['photos'] != null && data['photos'] is List) {
      _photoUrls = List<String>.from(data['photos']);
    }
  }

  @override
  void dispose() {
    _objetController.dispose();
    _partiesController.dispose();
    _decisionController.dispose();
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
      final contentieuxId = widget.contentieuxId ?? const Uuid().v4();
      final storagePath = 'contentieux/${widget.projectId}/$contentieuxId';
      
      final urls = await _firebase.uploadFiles(_localPhotoPaths, storagePath);
      
      setState(() {
        _photoUrls.addAll(urls);
        _localPhotoPaths.clear();
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documents uploadés avec succès')),
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

  Future<void> _saveContentieux() async {
    if (!_formKey.currentState!.validate()) return;

    if (_localPhotoPaths.isNotEmpty) {
      await _uploadPhotos();
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final contentieuxId = widget.contentieuxId ?? const Uuid().v4();
      
      final data = {
        'projectId': widget.projectId,
        'dateOuverture': _dateOuverture.toIso8601String(),
        'objet': _objetController.text.trim(),
        'parties': _partiesController.text.trim(),
        'nature': _selectedNature,
        'statut': _selectedStatut,
        'photos': _photoUrls,
        'commentaire': _commentaireController.text.trim(),
        'updatedAt': now.toIso8601String(),
        'createdBy': _auth.currentUserId ?? 'anonymous',
      };

      if (_selectedModeResolution != null) {
        data['modeResolution'] = _selectedModeResolution!;
      }
      if (_dateResolution != null) {
        data['dateResolution'] = _dateResolution!.toIso8601String();
      }
      if (_decisionController.text.trim().isNotEmpty) {
        data['decision'] = _decisionController.text.trim();
      }

      if (widget.contentieuxId == null) {
        data['id'] = contentieuxId;
        data['createdAt'] = now.toIso8601String();
        await _firebase.setDocument('contentieux', contentieuxId, data);
      } else {
        await _firebase.updateDocument('contentieux', widget.contentieuxId!, data);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.contentieuxId == null 
              ? 'Contentieux enregistré avec succès' 
              : 'Contentieux mis à jour'),
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
        title: Text(widget.contentieuxId == null 
          ? 'Nouveau Contentieux' 
          : 'Modifier Contentieux'),
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
              onPressed: _saveContentieux,
              tooltip: 'Enregistrer',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Date d'ouverture
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                title: const Text('Date d\'ouverture'),
                subtitle: Text(
                  '${_dateOuverture.day}/${_dateOuverture.month}/${_dateOuverture.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateOuverture,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _dateOuverture = date);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Objet
            TextFormField(
              controller: _objetController,
              decoration: const InputDecoration(
                labelText: 'Objet du contentieux *',
                hintText: 'Description brève du contentieux',
                prefixIcon: Icon(Icons.subject),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'L\'objet est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Parties
            TextFormField(
              controller: _partiesController,
              decoration: const InputDecoration(
                labelText: 'Parties impliquées *',
                hintText: 'Ex: Entreprise vs Propriétaire',
                prefixIcon: Icon(Icons.people_outline),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Les parties sont obligatoires';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Nature
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nature du contentieux',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _natures.map((nature) {
                        final isSelected = _selectedNature == nature['value'];
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                nature['icon'],
                                size: 18,
                                color: isSelected ? Colors.white : nature['color'],
                              ),
                              const SizedBox(width: 4),
                              Text(nature['label']!),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedNature = nature['value']!);
                            }
                          },
                          selectedColor: nature['color'],
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

            // Statut
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statut',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _statuts.map((statut) {
                        final isSelected = _selectedStatut == statut['value'];
                        return ChoiceChip(
                          label: Text(statut['label']!),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedStatut = statut['value']!);
                            }
                          },
                          selectedColor: statut['color'],
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

            // Mode de résolution (si résolu)
            if (_selectedStatut == 'Résolu' || _selectedStatut == 'Fermé') ...[
              DropdownButtonFormField<String>(
                value: _selectedModeResolution,
                decoration: const InputDecoration(
                  labelText: 'Mode de résolution',
                  prefixIcon: Icon(Icons.gavel),
                ),
                items: _modesResolution.map((mode) => DropdownMenuItem(
                  value: mode['value'],
                  child: Text(mode['label']!),
                )).toList(),
                onChanged: (value) {
                  setState(() => _selectedModeResolution = value);
                },
              ),
              const SizedBox(height: 16),

              // Date de résolution
              Card(
                child: ListTile(
                  leading: const Icon(Icons.event_available, color: Colors.green),
                  title: const Text('Date de résolution'),
                  subtitle: Text(
                    _dateResolution != null
                        ? '${_dateResolution!.day}/${_dateResolution!.month}/${_dateResolution!.year}'
                        : 'Non définie',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dateResolution ?? DateTime.now(),
                      firstDate: _dateOuverture,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _dateResolution = date);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Décision/Résolution
              TextFormField(
                controller: _decisionController,
                decoration: const InputDecoration(
                  labelText: 'Décision/Résolution',
                  hintText: 'Détails de la résolution',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
            ],

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

            // Photos/Documents
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
                          'Photos/Documents',
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
                          : 'Uploader les documents'),
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
              onPressed: _isLoading ? null : _saveContentieux,
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
