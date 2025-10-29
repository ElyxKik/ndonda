import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_service.dart';
import '../../services/image_service.dart';
import '../../utils/constants.dart';

class SensibilisationFirebaseForm extends StatefulWidget {
  final String projectId;
  final String? sensibilisationId;
  final Map<String, dynamic>? sensibilisationData;

  const SensibilisationFirebaseForm({
    super.key,
    required this.projectId,
    this.sensibilisationId,
    this.sensibilisationData,
  });

  @override
  State<SensibilisationFirebaseForm> createState() => _SensibilisationFirebaseFormState();
}

class _SensibilisationFirebaseFormState extends State<SensibilisationFirebaseForm> {
  final _formKey = GlobalKey<FormState>();
  final _firebase = FirebaseService.instance;
  final _auth = AuthService.instance;
  final _imageService = ImageService.instance;

  // Controllers
  late TextEditingController _nombreParticipantsController;
  late TextEditingController _nombreHommesController;
  late TextEditingController _nombreFemmesController;
  late TextEditingController _intervenantController;
  late TextEditingController _materielDistribueController;
  late TextEditingController _quantiteMaterielController;
  late TextEditingController _commentaireController;

  // State
  DateTime _selectedDate = DateTime.now();
  String _selectedTheme = 'VIH_SIDA';
  String _selectedType = 'formation';
  List<String> _photoUrls = [];
  List<String> _localPhotoPaths = [];
  bool _isLoading = false;
  bool _isUploading = false;

  // Options
  final List<Map<String, dynamic>> _themes = [
    {'value': 'IST', 'label': 'IST', 'icon': Icons.health_and_safety, 'color': Colors.red},
    {'value': 'VIH_SIDA', 'label': 'VIH/SIDA', 'icon': Icons.medical_services, 'color': Colors.red[700]},
    {'value': 'hygiene', 'label': 'Hygiène', 'icon': Icons.clean_hands, 'color': Colors.blue},
    {'value': 'covid19', 'label': 'COVID-19', 'icon': Icons.masks, 'color': Colors.orange},
    {'value': 'paludisme', 'label': 'Paludisme', 'icon': Icons.bug_report, 'color': Colors.green},
    {'value': 'autre', 'label': 'Autre', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  final List<Map<String, String>> _types = [
    {'value': 'formation', 'label': 'Formation'},
    {'value': 'causerie', 'label': 'Causerie'},
    {'value': 'affichage', 'label': 'Affichage'},
    {'value': 'distribution', 'label': 'Distribution'},
    {'value': 'projection', 'label': 'Projection'},
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
    if (widget.sensibilisationData != null) {
      _loadExistingData();
    }
  }

  void _initControllers() {
    _nombreParticipantsController = TextEditingController(text: '0');
    _nombreHommesController = TextEditingController(text: '0');
    _nombreFemmesController = TextEditingController(text: '0');
    _intervenantController = TextEditingController();
    _materielDistribueController = TextEditingController();
    _quantiteMaterielController = TextEditingController(text: '0');
    _commentaireController = TextEditingController();

    // Auto-calcul du total
    _nombreHommesController.addListener(_updateTotal);
    _nombreFemmesController.addListener(_updateTotal);
  }

  void _updateTotal() {
    final hommes = int.tryParse(_nombreHommesController.text) ?? 0;
    final femmes = int.tryParse(_nombreFemmesController.text) ?? 0;
    _nombreParticipantsController.text = (hommes + femmes).toString();
  }

  void _loadExistingData() {
    final data = widget.sensibilisationData!;
    _nombreParticipantsController.text = (data['nombreParticipants'] ?? 0).toString();
    _nombreHommesController.text = (data['nombreHommes'] ?? 0).toString();
    _nombreFemmesController.text = (data['nombreFemmes'] ?? 0).toString();
    _intervenantController.text = data['intervenant'] ?? '';
    _materielDistribueController.text = data['materielDistribue'] ?? '';
    _quantiteMaterielController.text = (data['quantiteMateriel'] ?? 0).toString();
    _commentaireController.text = data['commentaire'] ?? '';
    
    if (data['date'] != null) {
      _selectedDate = DateTime.parse(data['date']);
    }
    _selectedTheme = data['theme'] ?? 'VIH_SIDA';
    _selectedType = data['type'] ?? 'formation';
    
    if (data['photos'] != null && data['photos'] is List) {
      _photoUrls = List<String>.from(data['photos']);
    }
  }

  @override
  void dispose() {
    _nombreParticipantsController.dispose();
    _nombreHommesController.dispose();
    _nombreFemmesController.dispose();
    _intervenantController.dispose();
    _materielDistribueController.dispose();
    _quantiteMaterielController.dispose();
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
      final sensibilisationId = widget.sensibilisationId ?? const Uuid().v4();
      final storagePath = 'sensibilisations/${widget.projectId}/$sensibilisationId';
      
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

  Future<void> _saveSensibilisation() async {
    if (!_formKey.currentState!.validate()) return;

    if (_localPhotoPaths.isNotEmpty) {
      await _uploadPhotos();
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final sensibilisationId = widget.sensibilisationId ?? const Uuid().v4();
      
      final data = {
        'projectId': widget.projectId,
        'date': _selectedDate.toIso8601String(),
        'theme': _selectedTheme,
        'type': _selectedType,
        'nombreParticipants': int.tryParse(_nombreParticipantsController.text) ?? 0,
        'nombreHommes': int.tryParse(_nombreHommesController.text) ?? 0,
        'nombreFemmes': int.tryParse(_nombreFemmesController.text) ?? 0,
        'intervenant': _intervenantController.text.trim(),
        'materielDistribue': _materielDistribueController.text.trim(),
        'quantiteMateriel': int.tryParse(_quantiteMaterielController.text) ?? 0,
        'photos': _photoUrls,
        'commentaire': _commentaireController.text.trim(),
        'updatedAt': now.toIso8601String(),
        'createdBy': _auth.currentUserId ?? 'anonymous',
      };

      if (widget.sensibilisationId == null) {
        data['id'] = sensibilisationId;
        data['createdAt'] = now.toIso8601String();
        await _firebase.setDocument('sensibilisations', sensibilisationId, data);
      } else {
        await _firebase.updateDocument('sensibilisations', widget.sensibilisationId!, data);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.sensibilisationId == null 
              ? 'Sensibilisation enregistrée avec succès' 
              : 'Sensibilisation mise à jour'),
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
        title: Text(widget.sensibilisationId == null 
          ? 'Nouvelle Sensibilisation' 
          : 'Modifier Sensibilisation'),
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
              onPressed: _saveSensibilisation,
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
                title: const Text('Date de l\'activité'),
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
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Thème
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thème de sensibilisation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _themes.map((theme) {
                        final isSelected = _selectedTheme == theme['value'];
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                theme['icon'],
                                size: 18,
                                color: isSelected ? Colors.white : theme['color'],
                              ),
                              const SizedBox(width: 4),
                              Text(theme['label']!),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedTheme = theme['value']!);
                            }
                          },
                          selectedColor: theme['color'],
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

            // Type d'activité
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type d\'activité *',
                prefixIcon: Icon(Icons.category),
              ),
              items: _types.map((type) => DropdownMenuItem(
                value: type['value'],
                child: Text(type['label']!),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Participants
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Participants',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nombreHommesController,
                            decoration: const InputDecoration(
                              labelText: 'Hommes',
                              prefixIcon: Icon(Icons.male),
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
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _nombreFemmesController,
                            decoration: const InputDecoration(
                              labelText: 'Femmes',
                              prefixIcon: Icon(Icons.female),
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nombreParticipantsController,
                      decoration: const InputDecoration(
                        labelText: 'Total participants',
                        prefixIcon: Icon(Icons.people),
                        filled: true,
                        fillColor: Colors.grey,
                      ),
                      enabled: false,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Intervenant
            TextFormField(
              controller: _intervenantController,
              decoration: const InputDecoration(
                labelText: 'Intervenant',
                hintText: 'Nom de l\'intervenant',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Matériel distribué
            TextFormField(
              controller: _materielDistribueController,
              decoration: const InputDecoration(
                labelText: 'Matériel distribué',
                hintText: 'Type de matériel',
                prefixIcon: Icon(Icons.inventory),
              ),
            ),
            const SizedBox(height: 16),

            // Quantité de matériel
            TextFormField(
              controller: _quantiteMaterielController,
              decoration: const InputDecoration(
                labelText: 'Quantité de matériel',
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Commentaire
            TextFormField(
              controller: _commentaireController,
              decoration: const InputDecoration(
                labelText: 'Commentaire',
                hintText: 'Observations, retours, etc.',
                prefixIcon: Icon(Icons.comment),
              ),
              maxLines: 3,
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
              onPressed: _isLoading ? null : _saveSensibilisation,
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
