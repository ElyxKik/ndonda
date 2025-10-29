import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/consultation.dart';
import '../../services/database_service.dart';
import '../../services/image_service.dart';
import '../../utils/constants.dart';
import '../../widgets/photo_picker_widget.dart';

class ConsultationFormScreen extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic>? consultation;

  const ConsultationFormScreen({
    super.key,
    required this.projectId,
    this.consultation,
  });

  @override
  State<ConsultationFormScreen> createState() => _ConsultationFormScreenState();
}

class _ConsultationFormScreenState extends State<ConsultationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService.instance;
  final _imageService = ImageService.instance;

  late TextEditingController _sujetController;
  late TextEditingController _nombreParticipantsController;
  late TextEditingController _nombreHommesController;
  late TextEditingController _nombreFemmesController;
  late TextEditingController _localisationController;
  late TextEditingController _principauxPointsController;
  late TextEditingController _commentaireController;
  
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'reunion';
  List<String> _photos = [];
  bool _isLoading = false;

  final List<String> _types = [
    'reunion',
    'affichage',
    'radio',
    'television',
    'presse',
    'autre',
  ];

  @override
  void initState() {
    super.initState();
    _sujetController = TextEditingController();
    _nombreParticipantsController = TextEditingController(text: '0');
    _nombreHommesController = TextEditingController(text: '0');
    _nombreFemmesController = TextEditingController(text: '0');
    _localisationController = TextEditingController();
    _principauxPointsController = TextEditingController();
    _commentaireController = TextEditingController();

    if (widget.consultation != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final data = widget.consultation!;
    _sujetController.text = data['sujet'] ?? '';
    _nombreParticipantsController.text = data['nombreParticipants'].toString();
    _nombreHommesController.text = data['nombreHommes'].toString();
    _nombreFemmesController.text = data['nombreFemmes'].toString();
    _localisationController.text = data['localisation'] ?? '';
    _principauxPointsController.text = data['principauxPoints'] ?? '';
    _commentaireController.text = data['commentaire'] ?? '';
    _selectedDate = DateTime.parse(data['date']);
    _selectedType = data['type'] ?? 'reunion';
    
    if (data['photos'] != null && data['photos'].isNotEmpty) {
      _photos = data['photos'].split(',');
    }
  }

  @override
  void dispose() {
    _sujetController.dispose();
    _nombreParticipantsController.dispose();
    _nombreHommesController.dispose();
    _nombreFemmesController.dispose();
    _localisationController.dispose();
    _principauxPointsController.dispose();
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

  Future<void> _saveConsultation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final consultation = Consultation(
        id: widget.consultation?['id'] ?? const Uuid().v4(),
        projectId: widget.projectId,
        date: _selectedDate,
        type: _selectedType,
        sujet: _sujetController.text,
        nombreParticipants: int.parse(_nombreParticipantsController.text),
        nombreHommes: int.parse(_nombreHommesController.text),
        nombreFemmes: int.parse(_nombreFemmesController.text),
        localisation: _localisationController.text.isEmpty ? null : _localisationController.text,
        principauxPoints: _principauxPointsController.text.isEmpty ? null : _principauxPointsController.text,
        photos: _photos,
        commentaire: _commentaireController.text.isEmpty ? null : _commentaireController.text,
        createdAt: widget.consultation != null
            ? DateTime.parse(widget.consultation!['createdAt'])
            : DateTime.now(),
      );

      if (widget.consultation == null) {
        await _db.insert('consultations', consultation.toMap());
      } else {
        await _db.update('consultations', consultation.toMap(), consultation.id);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consultation enregistrée')),
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
        title: Text(widget.consultation == null ? 'Nouvelle Consultation' : 'Modifier Consultation'),
        backgroundColor: const Color(0xFF0288D1),
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
              onPressed: _saveConsultation,
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
                labelText: 'Type de consultation',
                prefixIcon: Icon(Icons.category),
              ),
              items: _types.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedType = value!);
              },
            ),
            const SizedBox(height: 16),

            // Sujet
            TextFormField(
              controller: _sujetController,
              decoration: const InputDecoration(
                labelText: 'Sujet *',
                prefixIcon: Icon(Icons.subject),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le sujet';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Nombre de participants
            TextFormField(
              controller: _nombreParticipantsController,
              decoration: const InputDecoration(
                labelText: 'Nombre total de participants *',
                prefixIcon: Icon(Icons.people),
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

            // Nombre Hommes
            TextFormField(
              controller: _nombreHommesController,
              decoration: const InputDecoration(
                labelText: 'Nombre d\'hommes',
                prefixIcon: Icon(Icons.man),
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

            // Nombre Femmes
            TextFormField(
              controller: _nombreFemmesController,
              decoration: const InputDecoration(
                labelText: 'Nombre de femmes',
                prefixIcon: Icon(Icons.woman),
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

            // Principaux points
            TextFormField(
              controller: _principauxPointsController,
              decoration: const InputDecoration(
                labelText: 'Principaux points discutés',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 4,
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
                onPressed: _isLoading ? null : _saveConsultation,
                icon: const Icon(Icons.save),
                label: Text(widget.consultation == null ? 'Enregistrer' : 'Mettre à jour'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
