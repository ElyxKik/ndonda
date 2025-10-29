import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/evenement.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../../services/image_service.dart';
import '../../utils/constants.dart';
import '../../widgets/photo_picker_widget.dart';

class EvenementFormScreen extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic>? evenement;

  const EvenementFormScreen({
    super.key,
    required this.projectId,
    this.evenement,
  });

  @override
  State<EvenementFormScreen> createState() => _EvenementFormScreenState();
}

class _EvenementFormScreenState extends State<EvenementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService.instance;
  final _locationService = LocationService.instance;
  final _imageService = ImageService.instance;

  late TextEditingController _titreController;
  late TextEditingController _descriptionController;
  late TextEditingController _commentaireController;
  
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'incident';
  List<String> _photos = [];
  double? _latitude;
  double? _longitude;
  String? _localisation;
  bool _isLoading = false;

  final List<String> _types = [
    'incident',
    'reunion',
    'visite',
    'inspection',
    'formation',
    'autre',
  ];

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController();
    _descriptionController = TextEditingController();
    _commentaireController = TextEditingController();

    if (widget.evenement != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final data = widget.evenement!;
    _titreController.text = data['titre'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    _commentaireController.text = data['commentaire'] ?? '';
    _selectedDate = DateTime.parse(data['date']);
    _selectedType = data['type'] ?? 'incident';
    _latitude = data['latitude'];
    _longitude = data['longitude'];
    _localisation = data['localisation'];
    
    if (data['photos'] != null && data['photos'].isNotEmpty) {
      _photos = data['photos'].split(',');
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      final address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _localisation = address ?? _locationService.formatCoordinates(
          position.latitude,
          position.longitude,
        );
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Localisation obtenue')),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'obtenir la localisation')),
        );
      }
    }
  }

  Future<void> _addPhoto() async {
    final path = await _imageService.pickImageFromCamera();
    if (path != null) {
      setState(() {
        _photos.add(path);
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  Future<void> _saveEvenement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final evenement = Evenement(
        id: widget.evenement?['id'] ?? const Uuid().v4(),
        projectId: widget.projectId,
        date: _selectedDate,
        titre: _titreController.text,
        description: _descriptionController.text,
        type: _selectedType,
        localisation: _localisation,
        latitude: _latitude,
        longitude: _longitude,
        photos: _photos,
        commentaire: _commentaireController.text.isEmpty ? null : _commentaireController.text,
        createdAt: widget.evenement != null
            ? DateTime.parse(widget.evenement!['createdAt'])
            : DateTime.now(),
      );

      if (widget.evenement == null) {
        await _db.insert('evenements', evenement.toMap());
      } else {
        await _db.update('evenements', evenement.toMap(), evenement.id);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Événement enregistré')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.evenement == null ? 'Nouvel Événement' : 'Modifier Événement'),
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
              onPressed: _saveEvenement,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                title: const Text('Date'),
                subtitle: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Type
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type d\'événement',
                prefixIcon: Icon(Icons.category),
              ),
              items: _types.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Titre
            TextFormField(
              controller: _titreController,
              decoration: const InputDecoration(
                labelText: 'Titre *',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un titre';
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

            // Localisation
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.location_on, color: AppColors.primary),
                    title: const Text('Localisation'),
                    subtitle: Text(_localisation ?? 'Non définie'),
                    trailing: IconButton(
                      icon: const Icon(Icons.my_location),
                      onPressed: _getCurrentLocation,
                    ),
                  ),
                  if (_latitude != null && _longitude != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        'Coordonnées: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
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
                onPressed: _isLoading ? null : _saveEvenement,
                icon: const Icon(Icons.save),
                label: Text(widget.evenement == null ? 'Enregistrer' : 'Mettre à jour'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
