import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/sensibilisation.dart';
import '../../services/database_service.dart';
import '../../services/image_service.dart';
import '../../utils/constants.dart';
import '../../widgets/photo_picker_widget.dart';

class SensibilisationFormScreen extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic>? sensibilisation;

  const SensibilisationFormScreen({
    super.key,
    required this.projectId,
    this.sensibilisation,
  });

  @override
  State<SensibilisationFormScreen> createState() => _SensibilisationFormScreenState();
}

class _SensibilisationFormScreenState extends State<SensibilisationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService.instance;
  final _imageService = ImageService.instance;

  late TextEditingController _nombreParticipantsController;
  late TextEditingController _nombreHommesController;
  late TextEditingController _nombreFemmesController;
  late TextEditingController _intervenantController;
  late TextEditingController _materielDistribueController;
  late TextEditingController _quantiteMaterielController;
  late TextEditingController _commentaireController;
  
  DateTime _selectedDate = DateTime.now();
  String _selectedTheme = 'IST';
  String _selectedType = 'formation';
  List<String> _photos = [];
  bool _isLoading = false;

  final List<String> _themes = [
    'IST',
    'VIH_SIDA',
    'hygiene',
    'covid19',
    'paludisme',
    'autre',
  ];

  final List<String> _types = [
    'formation',
    'causerie',
    'affichage',
    'distribution',
    'projection',
  ];

  @override
  void initState() {
    super.initState();
    _nombreParticipantsController = TextEditingController(text: '0');
    _nombreHommesController = TextEditingController(text: '0');
    _nombreFemmesController = TextEditingController(text: '0');
    _intervenantController = TextEditingController();
    _materielDistribueController = TextEditingController();
    _quantiteMaterielController = TextEditingController(text: '0');
    _commentaireController = TextEditingController();

    if (widget.sensibilisation != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final data = widget.sensibilisation!;
    _nombreParticipantsController.text = data['nombreParticipants'].toString();
    _nombreHommesController.text = data['nombreHommes'].toString();
    _nombreFemmesController.text = data['nombreFemmes'].toString();
    _intervenantController.text = data['intervenant'] ?? '';
    _materielDistribueController.text = data['materielDistribue'] ?? '';
    _quantiteMaterielController.text = (data['quantiteMateriel'] ?? 0).toString();
    _commentaireController.text = data['commentaire'] ?? '';
    _selectedDate = DateTime.parse(data['date']);
    _selectedTheme = data['theme'] ?? 'IST';
    _selectedType = data['type'] ?? 'formation';
    
    if (data['photos'] != null && data['photos'].isNotEmpty) {
      _photos = data['photos'].split(',');
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

  Future<void> _addPhoto() async {
    final path = await _imageService.pickImageFromCamera();
    if (path != null) {
      setState(() => _photos.add(path));
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _saveSensibilisation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final sensibilisation = Sensibilisation(
        id: widget.sensibilisation?['id'] ?? const Uuid().v4(),
        projectId: widget.projectId,
        date: _selectedDate,
        theme: _selectedTheme,
        type: _selectedType,
        nombreParticipants: int.parse(_nombreParticipantsController.text),
        nombreHommes: int.parse(_nombreHommesController.text),
        nombreFemmes: int.parse(_nombreFemmesController.text),
        intervenant: _intervenantController.text.isEmpty ? null : _intervenantController.text,
        materielDistribue: _materielDistribueController.text.isEmpty ? null : _materielDistribueController.text,
        quantiteMateriel: _quantiteMaterielController.text.isEmpty ? null : int.parse(_quantiteMaterielController.text),
        photos: _photos,
        commentaire: _commentaireController.text.isEmpty ? null : _commentaireController.text,
        createdAt: widget.sensibilisation != null
            ? DateTime.parse(widget.sensibilisation!['createdAt'])
            : DateTime.now(),
      );

      if (widget.sensibilisation == null) {
        await _db.insert('sensibilisations', sensibilisation.toMap());
      } else {
        await _db.update('sensibilisations', sensibilisation.toMap(), sensibilisation.id);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sensibilisation enregistrée')),
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
        title: Text(widget.sensibilisation == null ? 'Nouvelle Sensibilisation' : 'Modifier Sensibilisation'),
        backgroundColor: const Color(0xFFC2185B),
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

            // Thème
            DropdownButtonFormField<String>(
              value: _selectedTheme,
              decoration: const InputDecoration(
                labelText: 'Thème',
                prefixIcon: Icon(Icons.topic),
              ),
              items: _themes.map((theme) {
                return DropdownMenuItem(
                  value: theme,
                  child: Text(theme.replaceAll('_', '/')),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedTheme = value!);
              },
            ),
            const SizedBox(height: 16),

            // Type
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type d\'activité',
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

            // Nombre de participants
            TextFormField(
              controller: _nombreParticipantsController,
              decoration: const InputDecoration(
                labelText: 'Nombre de participants *',
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

            // Intervenant
            TextFormField(
              controller: _intervenantController,
              decoration: const InputDecoration(
                labelText: 'Intervenant',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Matériel distribué
            TextFormField(
              controller: _materielDistribueController,
              decoration: const InputDecoration(
                labelText: 'Matériel distribué',
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
                onPressed: _isLoading ? null : _saveSensibilisation,
                icon: const Icon(Icons.save),
                label: Text(widget.sensibilisation == null ? 'Enregistrer' : 'Mettre à jour'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
