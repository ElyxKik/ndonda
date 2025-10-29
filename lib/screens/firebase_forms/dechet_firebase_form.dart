import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_service.dart';
import '../../services/image_service.dart';
import '../../utils/constants.dart';

class DechetFirebaseForm extends StatefulWidget {
  final String projectId;
  final String? dechetId;
  final Map<String, dynamic>? dechetData;

  const DechetFirebaseForm({
    super.key,
    required this.projectId,
    this.dechetId,
    this.dechetData,
  });

  @override
  State<DechetFirebaseForm> createState() => _DechetFirebaseFormState();
}

class _DechetFirebaseFormState extends State<DechetFirebaseForm> {
  final _formKey = GlobalKey<FormState>();
  final _firebase = FirebaseService.instance;
  final _auth = AuthService.instance;
  final _imageService = ImageService.instance;

  // Controllers
  late TextEditingController _descriptionController;
  late TextEditingController _quantiteController;
  late TextEditingController _destinationController;
  late TextEditingController _commentaireController;

  // State
  DateTime _selectedDate = DateTime.now();
  String _selectedTypeDechet = 'recyclable';
  String _selectedUnite = 'kg';
  String _selectedModeGestion = 'recyclage';
  List<String> _photoUrls = [];
  List<String> _localPhotoPaths = [];
  bool _isLoading = false;
  bool _isUploading = false;

  // Options
  final List<Map<String, dynamic>> _typesDechet = [
    {'value': 'dangereux', 'label': 'Dangereux', 'icon': Icons.warning, 'color': Colors.red},
    {'value': 'non_dangereux', 'label': 'Non dangereux', 'icon': Icons.check_circle, 'color': Colors.green},
    {'value': 'recyclable', 'label': 'Recyclable', 'icon': Icons.recycling, 'color': Colors.blue},
    {'value': 'organique', 'label': 'Organique', 'icon': Icons.eco, 'color': Colors.green[700]},
  ];

  final List<String> _unites = ['kg', 'tonnes', 'm3', 'unites'];

  final List<Map<String, String>> _modesGestion = [
    {'value': 'recyclage', 'label': 'Recyclage'},
    {'value': 'enfouissement', 'label': 'Enfouissement'},
    {'value': 'incineration', 'label': 'Incinération'},
    {'value': 'valorisation', 'label': 'Valorisation'},
    {'value': 'compostage', 'label': 'Compostage'},
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
    if (widget.dechetData != null) {
      _loadExistingData();
    }
  }

  void _initControllers() {
    _descriptionController = TextEditingController();
    _quantiteController = TextEditingController(text: '0');
    _destinationController = TextEditingController();
    _commentaireController = TextEditingController();
  }

  void _loadExistingData() {
    final data = widget.dechetData!;
    _descriptionController.text = data['description'] ?? '';
    _quantiteController.text = (data['quantite'] ?? 0).toString();
    _destinationController.text = data['destination'] ?? '';
    _commentaireController.text = data['commentaire'] ?? '';
    
    if (data['date'] != null) {
      _selectedDate = DateTime.parse(data['date']);
    }
    _selectedTypeDechet = data['typeDechet'] ?? 'recyclable';
    _selectedUnite = data['unite'] ?? 'kg';
    _selectedModeGestion = data['modeGestion'] ?? 'recyclage';
    
    if (data['photos'] != null && data['photos'] is List) {
      _photoUrls = List<String>.from(data['photos']);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantiteController.dispose();
    _destinationController.dispose();
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
      final dechetId = widget.dechetId ?? const Uuid().v4();
      final storagePath = 'dechets/${widget.projectId}/$dechetId';
      
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

  Future<void> _saveDechet() async {
    if (!_formKey.currentState!.validate()) return;

    if (_localPhotoPaths.isNotEmpty) {
      await _uploadPhotos();
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final dechetId = widget.dechetId ?? const Uuid().v4();
      
      final data = {
        'projectId': widget.projectId,
        'date': _selectedDate.toIso8601String(),
        'typeDechet': _selectedTypeDechet,
        'description': _descriptionController.text.trim(),
        'quantite': double.tryParse(_quantiteController.text) ?? 0,
        'unite': _selectedUnite,
        'modeGestion': _selectedModeGestion,
        'destination': _destinationController.text.trim(),
        'photos': _photoUrls,
        'commentaire': _commentaireController.text.trim(),
        'updatedAt': now.toIso8601String(),
        'createdBy': _auth.currentUserId ?? 'anonymous',
      };

      if (widget.dechetId == null) {
        data['id'] = dechetId;
        data['createdAt'] = now.toIso8601String();
        await _firebase.setDocument('dechets', dechetId, data);
      } else {
        await _firebase.updateDocument('dechets', widget.dechetId!, data);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.dechetId == null 
              ? 'Déchet enregistré avec succès' 
              : 'Déchet mis à jour'),
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
        title: Text(widget.dechetId == null 
          ? 'Nouveau Déchet' 
          : 'Modifier Déchet'),
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
              onPressed: _saveDechet,
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
                title: const Text('Date de collecte/gestion'),
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

            // Type de déchet
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Type de déchet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _typesDechet.map((type) {
                        final isSelected = _selectedTypeDechet == type['value'];
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                type['icon'],
                                size: 18,
                                color: isSelected ? Colors.white : type['color'],
                              ),
                              const SizedBox(width: 4),
                              Text(type['label']!),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedTypeDechet = type['value']!);
                            }
                          },
                          selectedColor: type['color'],
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

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Description du déchet',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La description est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Quantité et Unité
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantiteController,
                    decoration: const InputDecoration(
                      labelText: 'Quantité *',
                      prefixIcon: Icon(Icons.scale),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Obligatoire';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Nombre invalide';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnite,
                    decoration: const InputDecoration(
                      labelText: 'Unité',
                    ),
                    items: _unites.map((unite) => DropdownMenuItem(
                      value: unite,
                      child: Text(unite),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedUnite = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mode de gestion
            DropdownButtonFormField<String>(
              value: _selectedModeGestion,
              decoration: const InputDecoration(
                labelText: 'Mode de gestion *',
                prefixIcon: Icon(Icons.settings),
              ),
              items: _modesGestion.map((mode) => DropdownMenuItem(
                value: mode['value'],
                child: Text(mode['label']!),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedModeGestion = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Destination
            TextFormField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination',
                hintText: 'Lieu de destination',
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
              onPressed: _isLoading ? null : _saveDechet,
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
