import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/contentieux.dart';
import '../../services/database_service.dart';
import '../../services/image_service.dart';
import '../../utils/constants.dart';
import '../../widgets/photo_picker_widget.dart';

class ContentieuxFormScreen extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic>? contentieux;

  const ContentieuxFormScreen({
    super.key,
    required this.projectId,
    this.contentieux,
  });

  @override
  State<ContentieuxFormScreen> createState() => _ContentieuxFormScreenState();
}

class _ContentieuxFormScreenState extends State<ContentieuxFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService.instance;
  final _imageService = ImageService.instance;

  late TextEditingController _objetController;
  late TextEditingController _partiesController;
  late TextEditingController _decisionController;
  late TextEditingController _commentaireController;
  
  DateTime _dateOuverture = DateTime.now();
  DateTime? _dateResolution;
  String _selectedNature = 'foncier';
  String _selectedStatut = 'Ouvert';
  String? _selectedModeResolution;
  List<String> _photos = [];
  bool _isLoading = false;

  final List<String> _natures = [
    'foncier',
    'commercial',
    'social',
    'environnemental',
    'autre',
  ];

  final List<String> _modesResolution = [
    'amiable',
    'mediation',
    'arbitrage',
    'judiciaire',
  ];

  @override
  void initState() {
    super.initState();
    _objetController = TextEditingController();
    _partiesController = TextEditingController();
    _decisionController = TextEditingController();
    _commentaireController = TextEditingController();

    if (widget.contentieux != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final data = widget.contentieux!;
    _objetController.text = data['objet'] ?? '';
    _partiesController.text = data['parties'] ?? '';
    _decisionController.text = data['decision'] ?? '';
    _commentaireController.text = data['commentaire'] ?? '';
    _dateOuverture = DateTime.parse(data['dateOuverture']);
    _dateResolution = data['dateResolution'] != null ? DateTime.parse(data['dateResolution']) : null;
    _selectedNature = data['nature'] ?? 'foncier';
    _selectedStatut = data['statut'] ?? 'Ouvert';
    _selectedModeResolution = data['modeResolution'];
    
    if (data['photos'] != null && data['photos'].isNotEmpty) {
      _photos = data['photos'].split(',');
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

  Future<void> _addPhoto() async {
    final path = await _imageService.pickImageFromCamera();
    if (path != null) {
      setState(() => _photos.add(path));
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _saveContentieux() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final contentieux = Contentieux(
        id: widget.contentieux?['id'] ?? const Uuid().v4(),
        projectId: widget.projectId,
        dateOuverture: _dateOuverture,
        objet: _objetController.text,
        parties: _partiesController.text,
        nature: _selectedNature,
        statut: _selectedStatut,
        modeResolution: _selectedModeResolution,
        dateResolution: _dateResolution,
        decision: _decisionController.text.isEmpty ? null : _decisionController.text,
        photos: _photos,
        commentaire: _commentaireController.text.isEmpty ? null : _commentaireController.text,
        createdAt: widget.contentieux != null
            ? DateTime.parse(widget.contentieux!['createdAt'])
            : DateTime.now(),
      );

      if (widget.contentieux == null) {
        await _db.insert('contentieux', contentieux.toMap());
      } else {
        await _db.update('contentieux', contentieux.toMap(), contentieux.id);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contentieux enregistré')),
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
        title: Text(widget.contentieux == null ? 'Nouveau Contentieux' : 'Modifier Contentieux'),
        backgroundColor: const Color(0xFF455A64),
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
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date d'ouverture
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                title: const Text('Date d\'ouverture'),
                subtitle: Text('${_dateOuverture.day}/${_dateOuverture.month}/${_dateOuverture.year}'),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateOuverture,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => _dateOuverture = date);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Nature
            DropdownButtonFormField<String>(
              value: _selectedNature,
              decoration: const InputDecoration(
                labelText: 'Nature du contentieux',
                prefixIcon: Icon(Icons.category),
              ),
              items: _natures.map((nature) {
                return DropdownMenuItem(
                  value: nature,
                  child: Text(nature.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedNature = value!);
              },
            ),
            const SizedBox(height: 16),

            // Objet
            TextFormField(
              controller: _objetController,
              decoration: const InputDecoration(
                labelText: 'Objet du contentieux *',
                prefixIcon: Icon(Icons.subject),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer l\'objet';
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
                prefixIcon: Icon(Icons.people),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer les parties';
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
              items: StatusOptions.contentieuxStatut.map((statut) {
                return DropdownMenuItem(
                  value: statut,
                  child: Text(statut),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedStatut = value!);
              },
            ),
            const SizedBox(height: 16),

            // Mode de résolution
            DropdownButtonFormField<String?>(
              value: _selectedModeResolution,
              decoration: const InputDecoration(
                labelText: 'Mode de résolution',
                prefixIcon: Icon(Icons.gavel),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Non défini'),
                ),
                ..._modesResolution.map((mode) {
                  return DropdownMenuItem<String?>(
                    value: mode,
                    child: Text(mode.toUpperCase()),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _selectedModeResolution = value);
              },
            ),
            const SizedBox(height: 16),

            // Date de résolution
            Card(
              child: ListTile(
                leading: const Icon(Icons.event_available, color: AppColors.primary),
                title: const Text('Date de résolution'),
                subtitle: Text(_dateResolution != null
                    ? '${_dateResolution!.day}/${_dateResolution!.month}/${_dateResolution!.year}'
                    : 'Non résolue'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_dateResolution != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _dateResolution = null);
                        },
                      ),
                    const Icon(Icons.edit),
                  ],
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateResolution ?? DateTime.now(),
                    firstDate: _dateOuverture,
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => _dateResolution = date);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Décision
            TextFormField(
              controller: _decisionController,
              decoration: const InputDecoration(
                labelText: 'Décision / Résolution',
                prefixIcon: Icon(Icons.description),
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
                onPressed: _isLoading ? null : _saveContentieux,
                icon: const Icon(Icons.save),
                label: Text(widget.contentieux == null ? 'Enregistrer' : 'Mettre à jour'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
