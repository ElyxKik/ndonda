import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_service.dart';
import '../../services/image_service.dart';
import '../../utils/constants.dart';

class EquipementFirebaseForm extends StatefulWidget {
  final String projectId;
  final String? equipementId;
  final Map<String, dynamic>? equipementData;

  const EquipementFirebaseForm({
    super.key,
    required this.projectId,
    this.equipementId,
    this.equipementData,
  });

  @override
  State<EquipementFirebaseForm> createState() => _EquipementFirebaseFormState();
}

class _EquipementFirebaseFormState extends State<EquipementFirebaseForm> {
  final _formKey = GlobalKey<FormState>();
  final _firebase = FirebaseService.instance;
  final _auth = AuthService.instance;
  final _imageService = ImageService.instance;

  // Controllers
  late TextEditingController _designationController;
  late TextEditingController _quantiteDemandeeController;
  late TextEditingController _quantiteFournieController;
  late TextEditingController _fournisseurController;
  late TextEditingController _commentaireController;

  // State
  DateTime _selectedDate = DateTime.now();
  String _selectedTypeEquipement = 'EPI';
  String _selectedStatut = 'Demandé';
  List<String> _photoUrls = [];
  List<String> _localPhotoPaths = [];
  bool _isLoading = false;
  bool _isUploading = false;

  // Options
  final List<Map<String, String>> _typesEquipement = [
    {'value': 'EPI', 'label': 'EPI (Équipement de Protection Individuelle)'},
    {'value': 'EPC', 'label': 'EPC (Équipement de Protection Collective)'},
  ];

  final List<Map<String, dynamic>> _statuts = [
    {'value': 'Demandé', 'label': 'Demandé', 'color': Colors.orange},
    {'value': 'En cours', 'label': 'En cours', 'color': Colors.blue},
    {'value': 'Fourni', 'label': 'Fourni', 'color': Colors.green},
    {'value': 'Partiel', 'label': 'Partiel', 'color': Colors.amber},
  ];

  // Exemples d'équipements EPI
  final List<String> _exempleEPI = [
    'Casque de sécurité',
    'Gants de protection',
    'Lunettes de sécurité',
    'Chaussures de sécurité',
    'Gilet haute visibilité',
    'Masque respiratoire',
    'Harnais de sécurité',
    'Bouchons d\'oreilles',
  ];

  // Exemples d'équipements EPC
  final List<String> _exempleEPC = [
    'Extincteur',
    'Trousse de premiers secours',
    'Barrière de sécurité',
    'Signalisation',
    'Échafaudage',
    'Filet de sécurité',
    'Cône de signalisation',
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
    if (widget.equipementData != null) {
      _loadExistingData();
    }
  }

  void _initControllers() {
    _designationController = TextEditingController();
    _quantiteDemandeeController = TextEditingController(text: '1');
    _quantiteFournieController = TextEditingController(text: '0');
    _fournisseurController = TextEditingController();
    _commentaireController = TextEditingController();
  }

  void _loadExistingData() {
    final data = widget.equipementData!;
    _designationController.text = data['designation'] ?? '';
    _quantiteDemandeeController.text = (data['quantiteDemandee'] ?? 1).toString();
    _quantiteFournieController.text = (data['quantiteFournie'] ?? 0).toString();
    _fournisseurController.text = data['fournisseur'] ?? '';
    _commentaireController.text = data['commentaire'] ?? '';
    
    if (data['date'] != null) {
      _selectedDate = DateTime.parse(data['date']);
    }
    _selectedTypeEquipement = data['typeEquipement'] ?? 'EPI';
    _selectedStatut = data['statut'] ?? 'Demandé';
    
    if (data['photos'] != null && data['photos'] is List) {
      _photoUrls = List<String>.from(data['photos']);
    }
  }

  @override
  void dispose() {
    _designationController.dispose();
    _quantiteDemandeeController.dispose();
    _quantiteFournieController.dispose();
    _fournisseurController.dispose();
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
      final equipementId = widget.equipementId ?? const Uuid().v4();
      final storagePath = 'equipements/${widget.projectId}/$equipementId';
      
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

  Future<void> _saveEquipement() async {
    if (!_formKey.currentState!.validate()) return;

    // Upload photos si nécessaire
    if (_localPhotoPaths.isNotEmpty) {
      await _uploadPhotos();
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final equipementId = widget.equipementId ?? const Uuid().v4();
      
      final data = {
        'projectId': widget.projectId,
        'date': _selectedDate.toIso8601String(),
        'typeEquipement': _selectedTypeEquipement,
        'designation': _designationController.text.trim(),
        'quantiteDemandee': int.tryParse(_quantiteDemandeeController.text) ?? 1,
        'quantiteFournie': int.tryParse(_quantiteFournieController.text) ?? 0,
        'fournisseur': _fournisseurController.text.trim(),
        'statut': _selectedStatut,
        'photos': _photoUrls,
        'commentaire': _commentaireController.text.trim(),
        'updatedAt': now.toIso8601String(),
        'createdBy': _auth.currentUserId ?? 'anonymous',
      };

      if (widget.equipementId == null) {
        data['id'] = equipementId;
        data['createdAt'] = now.toIso8601String();
        await _firebase.setDocument('equipements', equipementId, data);
      } else {
        await _firebase.updateDocument('equipements', widget.equipementId!, data);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.equipementId == null 
              ? 'Équipement enregistré avec succès' 
              : 'Équipement mis à jour'),
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

  void _showExempleDialog() {
    final exemples = _selectedTypeEquipement == 'EPI' ? _exempleEPI : _exempleEPC;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exemples ${_selectedTypeEquipement}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: exemples.map((exemple) => ListTile(
              title: Text(exemple),
              onTap: () {
                _designationController.text = exemple;
                Navigator.pop(context);
              },
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.equipementId == null 
          ? 'Nouvel Équipement' 
          : 'Modifier Équipement'),
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
              onPressed: _saveEquipement,
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
                title: const Text('Date'),
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

            // Type d'équipement
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Type d\'équipement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(_typesEquipement.map((type) => RadioListTile<String>(
                      title: Text(type['label']!),
                      value: type['value']!,
                      groupValue: _selectedTypeEquipement,
                      onChanged: (value) {
                        setState(() => _selectedTypeEquipement = value!);
                      },
                      activeColor: AppColors.primary,
                    ))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Désignation
            TextFormField(
              controller: _designationController,
              decoration: InputDecoration(
                labelText: 'Désignation *',
                hintText: 'Nom de l\'équipement',
                prefixIcon: const Icon(Icons.construction),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.lightbulb_outline),
                  onPressed: _showExempleDialog,
                  tooltip: 'Voir des exemples',
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La désignation est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Quantités
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantiteDemandeeController,
                    decoration: const InputDecoration(
                      labelText: 'Quantité demandée *',
                      prefixIcon: Icon(Icons.shopping_cart),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Obligatoire';
                      }
                      if (int.tryParse(value) == null || int.parse(value) < 1) {
                        return 'Nombre invalide';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _quantiteFournieController,
                    decoration: const InputDecoration(
                      labelText: 'Quantité fournie',
                      prefixIcon: Icon(Icons.check_circle_outline),
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
            const SizedBox(height: 16),

            // Fournisseur
            TextFormField(
              controller: _fournisseurController,
              decoration: const InputDecoration(
                labelText: 'Fournisseur',
                hintText: 'Nom du fournisseur',
                prefixIcon: Icon(Icons.business),
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

            // Commentaire
            TextFormField(
              controller: _commentaireController,
              decoration: const InputDecoration(
                labelText: 'Commentaire',
                hintText: 'Informations complémentaires',
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
              onPressed: _isLoading ? null : _saveEquipement,
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
