import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/dechet.dart';
import '../../services/database_service.dart';
import '../../services/image_service.dart';
import '../../utils/constants.dart';
import '../../widgets/photo_picker_widget.dart';

class DechetFormScreen extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic>? dechet;

  const DechetFormScreen({
    super.key,
    required this.projectId,
    this.dechet,
  });

  @override
  State<DechetFormScreen> createState() => _DechetFormScreenState();
}

class _DechetFormScreenState extends State<DechetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService.instance;
  final _imageService = ImageService.instance;

  late TextEditingController _descriptionController;
  late TextEditingController _quantiteController;
  late TextEditingController _destinationController;
  late TextEditingController _commentaireController;
  
  DateTime _selectedDate = DateTime.now();
  String _selectedTypeDechet = 'non_dangereux';
  String _selectedUnite = 'kg';
  String _selectedModeGestion = 'recyclage';
  List<String> _photos = [];
  bool _isLoading = false;

  final List<String> _typesDechet = [
    'dangereux',
    'non_dangereux',
    'recyclable',
    'organique',
  ];

  final List<String> _unites = ['kg', 'tonnes', 'm3', 'unites'];

  final List<String> _modesGestion = [
    'recyclage',
    'enfouissement',
    'incineration',
    'valorisation',
    'compostage',
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _quantiteController = TextEditingController();
    _destinationController = TextEditingController();
    _commentaireController = TextEditingController();

    if (widget.dechet != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final data = widget.dechet!;
    _descriptionController.text = data['description'] ?? '';
    _quantiteController.text = data['quantite'].toString();
    _destinationController.text = data['destination'] ?? '';
    _commentaireController.text = data['commentaire'] ?? '';
    _selectedDate = DateTime.parse(data['date']);
    _selectedTypeDechet = data['typeDechet'] ?? 'non_dangereux';
    _selectedUnite = data['unite'] ?? 'kg';
    _selectedModeGestion = data['modeGestion'] ?? 'recyclage';
    
    if (data['photos'] != null && data['photos'].isNotEmpty) {
      _photos = data['photos'].split(',');
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

  Future<void> _addPhoto() async {
    final path = await _imageService.pickImageFromCamera();
    if (path != null) {
      setState(() => _photos.add(path));
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _saveDechet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dechet = Dechet(
        id: widget.dechet?['id'] ?? const Uuid().v4(),
        projectId: widget.projectId,
        date: _selectedDate,
        typeDechet: _selectedTypeDechet,
        description: _descriptionController.text,
        quantite: double.parse(_quantiteController.text),
        unite: _selectedUnite,
        modeGestion: _selectedModeGestion,
        destination: _destinationController.text.isEmpty ? null : _destinationController.text,
        photos: _photos,
        commentaire: _commentaireController.text.isEmpty ? null : _commentaireController.text,
        createdAt: widget.dechet != null
            ? DateTime.parse(widget.dechet!['createdAt'])
            : DateTime.now(),
      );

      if (widget.dechet == null) {
        await _db.insert('dechets', dechet.toMap());
      } else {
        await _db.update('dechets', dechet.toMap(), dechet.id);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Déchet enregistré')),
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
        title: Text(widget.dechet == null ? 'Nouveau Déchet' : 'Modifier Déchet'),
        backgroundColor: const Color(0xFF5D4037),
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

            // Type de déchet
            DropdownButtonFormField<String>(
              value: _selectedTypeDechet,
              decoration: const InputDecoration(
                labelText: 'Type de déchet',
                prefixIcon: Icon(Icons.category),
              ),
              items: _typesDechet.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase().replaceAll('_', ' ')),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedTypeDechet = value!);
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
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requis';
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
                    items: _unites.map((unite) {
                      return DropdownMenuItem(
                        value: unite,
                        child: Text(unite),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedUnite = value!);
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
                labelText: 'Mode de gestion',
                prefixIcon: Icon(Icons.recycling),
              ),
              items: _modesGestion.map((mode) {
                return DropdownMenuItem(
                  value: mode,
                  child: Text(mode.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedModeGestion = value!);
              },
            ),
            const SizedBox(height: 16),

            // Destination
            TextFormField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination',
                prefixIcon: Icon(Icons.place),
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
                onPressed: _isLoading ? null : _saveDechet,
                icon: const Icon(Icons.save),
                label: Text(widget.dechet == null ? 'Enregistrer' : 'Mettre à jour'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
