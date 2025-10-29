import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/pges_mesure.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../../services/image_service.dart';
import '../../utils/constants.dart';
import '../../widgets/photo_picker_widget.dart';

class PgesFormScreen extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic>? mesure;

  const PgesFormScreen({
    super.key,
    required this.projectId,
    this.mesure,
  });

  @override
  State<PgesFormScreen> createState() => _PgesFormScreenState();
}

class _PgesFormScreenState extends State<PgesFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService.instance;
  final _locationService = LocationService.instance;
  final _imageService = ImageService.instance;

  late TextEditingController _mesureController;
  late TextEditingController _responsableController;
  late TextEditingController _observationsController;
  
  DateTime _selectedDate = DateTime.now();
  String _selectedCategorie = 'environnement';
  String _selectedStatut = 'Non commencé';
  List<String> _photos = [];
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;

  final List<String> _categories = [
    'environnement',
    'social',
    'sante_securite',
  ];

  @override
  void initState() {
    super.initState();
    _mesureController = TextEditingController();
    _responsableController = TextEditingController();
    _observationsController = TextEditingController();

    if (widget.mesure != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final data = widget.mesure!;
    _mesureController.text = data['mesure'] ?? '';
    _responsableController.text = data['responsable'] ?? '';
    _observationsController.text = data['observations'] ?? '';
    _selectedDate = DateTime.parse(data['date']);
    _selectedCategorie = data['categorie'] ?? 'environnement';
    _selectedStatut = data['statut'] ?? 'Non commencé';
    _latitude = data['latitude'];
    _longitude = data['longitude'];
    
    if (data['photos'] != null && data['photos'].isNotEmpty) {
      _photos = data['photos'].split(',');
    }
  }

  @override
  void dispose() {
    _mesureController.dispose();
    _responsableController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
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

  Future<void> _saveMesure() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final mesure = PgesMesure(
        id: widget.mesure?['id'] ?? const Uuid().v4(),
        projectId: widget.projectId,
        date: _selectedDate,
        categorie: _selectedCategorie,
        mesure: _mesureController.text,
        statut: _selectedStatut,
        responsable: _responsableController.text,
        observations: _observationsController.text.isEmpty ? null : _observationsController.text,
        photos: _photos,
        latitude: _latitude,
        longitude: _longitude,
        createdAt: widget.mesure != null
            ? DateTime.parse(widget.mesure!['createdAt'])
            : DateTime.now(),
      );

      if (widget.mesure == null) {
        await _db.insert('pges_mesures', mesure.toMap());
      } else {
        await _db.update('pges_mesures', mesure.toMap(), mesure.id);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mesure PGES enregistrée')),
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
        title: Text(widget.mesure == null ? 'Nouvelle Mesure PGES' : 'Modifier Mesure PGES'),
        backgroundColor: AppColors.success,
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
              onPressed: _saveMesure,
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
                  child: Text(cat.toUpperCase().replaceAll('_', ' ')),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategorie = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Mesure
            TextFormField(
              controller: _mesureController,
              decoration: const InputDecoration(
                labelText: 'Mesure de sauvegarde *',
                prefixIcon: Icon(Icons.checklist),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez décrire la mesure';
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
              items: StatusOptions.pgesStatut.map((statut) {
                return DropdownMenuItem(
                  value: statut,
                  child: Text(statut),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatut = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Responsable
            TextFormField(
              controller: _responsableController,
              decoration: const InputDecoration(
                labelText: 'Responsable *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le responsable';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Localisation
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on, color: AppColors.primary),
                title: const Text('Géolocalisation'),
                subtitle: _latitude != null && _longitude != null
                    ? Text('${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}')
                    : const Text('Non définie'),
                trailing: IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: _getCurrentLocation,
                ),
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

            // Observations
            TextFormField(
              controller: _observationsController,
              decoration: const InputDecoration(
                labelText: 'Observations',
                prefixIcon: Icon(Icons.comment),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveMesure,
                icon: const Icon(Icons.save),
                label: Text(widget.mesure == null ? 'Enregistrer' : 'Mettre à jour'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
