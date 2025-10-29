import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/incident.dart';
import '../../services/database_service.dart';
import '../../services/image_service.dart';
import '../../utils/constants.dart';
import '../../widgets/photo_picker_widget.dart';

class IncidentFormScreen extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic>? incident;

  const IncidentFormScreen({
    super.key,
    required this.projectId,
    this.incident,
  });

  @override
  State<IncidentFormScreen> createState() => _IncidentFormScreenState();
}

class _IncidentFormScreenState extends State<IncidentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService.instance;
  final _imageService = ImageService.instance;

  late TextEditingController _descriptionController;
  late TextEditingController _personneAffecteeController;
  late TextEditingController _fonctionController;
  late TextEditingController _mesuresPrisesController;
  late TextEditingController _joursArretController;
  late TextEditingController _localisationController;
  late TextEditingController _commentaireController;
  
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'accident_travail';
  String _selectedGravite = 'moyen';
  List<String> _photos = [];
  bool _isLoading = false;

  final List<String> _types = [
    'maladie',
    'accident_travail',
    'accident_circulation',
    'autre',
  ];

  final List<String> _gravites = [
    'leger',
    'moyen',
    'grave',
    'mortel',
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _personneAffecteeController = TextEditingController();
    _fonctionController = TextEditingController();
    _mesuresPrisesController = TextEditingController();
    _joursArretController = TextEditingController(text: '0');
    _localisationController = TextEditingController();
    _commentaireController = TextEditingController();

    if (widget.incident != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final data = widget.incident!;
    _descriptionController.text = data['description'] ?? '';
    _personneAffecteeController.text = data['personneAffectee'] ?? '';
    _fonctionController.text = data['fonction'] ?? '';
    _mesuresPrisesController.text = data['mesuresPrises'] ?? '';
    _joursArretController.text = data['joursArretTravail'].toString();
    _localisationController.text = data['localisation'] ?? '';
    _commentaireController.text = data['commentaire'] ?? '';
    _selectedDate = DateTime.parse(data['date']);
    _selectedType = data['type'] ?? 'accident_travail';
    _selectedGravite = data['gravite'] ?? 'moyen';
    
    if (data['photos'] != null && data['photos'].isNotEmpty) {
      _photos = data['photos'].split(',');
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

  Future<void> _addPhoto() async {
    final path = await _imageService.pickImageFromCamera();
    if (path != null) {
      setState(() => _photos.add(path));
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _saveIncident() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final incident = Incident(
        id: widget.incident?['id'] ?? const Uuid().v4(),
        projectId: widget.projectId,
        date: _selectedDate,
        type: _selectedType,
        gravite: _selectedGravite,
        description: _descriptionController.text,
        personneAffectee: _personneAffecteeController.text,
        fonction: _fonctionController.text.isEmpty ? null : _fonctionController.text,
        mesuresPrises: _mesuresPrisesController.text,
        joursArretTravail: int.parse(_joursArretController.text),
        localisation: _localisationController.text.isEmpty ? null : _localisationController.text,
        photos: _photos,
        commentaire: _commentaireController.text.isEmpty ? null : _commentaireController.text,
        createdAt: widget.incident != null
            ? DateTime.parse(widget.incident!['createdAt'])
            : DateTime.now(),
      );

      if (widget.incident == null) {
        await _db.insert('incidents', incident.toMap());
      } else {
        await _db.update('incidents', incident.toMap(), incident.id);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident enregistré')),
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
        title: Text(widget.incident == null ? 'Nouvel Incident' : 'Modifier Incident'),
        backgroundColor: const Color(0xFFD32F2F),
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
                subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Type
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type d\'incident',
                prefixIcon: Icon(Icons.category),
              ),
              items: _types.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase().replaceAll('_', ' ')),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedType = value!);
              },
            ),
            const SizedBox(height: 16),

            // Gravité
            DropdownButtonFormField<String>(
              value: _selectedGravite,
              decoration: const InputDecoration(
                labelText: 'Gravité',
                prefixIcon: Icon(Icons.warning),
              ),
              items: _gravites.map((gravite) {
                return DropdownMenuItem(
                  value: gravite,
                  child: Text(gravite.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedGravite = value!);
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
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une description';
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
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le nom';
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
                prefixIcon: Icon(Icons.work),
              ),
            ),
            const SizedBox(height: 16),

            // Mesures prises
            TextFormField(
              controller: _mesuresPrisesController,
              decoration: const InputDecoration(
                labelText: 'Mesures prises *',
                prefixIcon: Icon(Icons.medical_services),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez décrire les mesures prises';
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
                prefixIcon: Icon(Icons.event_busy),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Requis';
                }
                if (int.tryParse(value) == null) {
                  return 'Nombre invalide';
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
                prefixIcon: Icon(Icons.location_on),
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
                onPressed: _isLoading ? null : _saveIncident,
                icon: const Icon(Icons.save),
                label: Text(widget.incident == null ? 'Enregistrer' : 'Mettre à jour'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
