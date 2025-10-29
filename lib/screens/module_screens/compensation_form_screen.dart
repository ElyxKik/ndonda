import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/compensation.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../../services/image_service.dart';
import '../../utils/constants.dart';
import '../../widgets/photo_picker_widget.dart';

class CompensationFormScreen extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic>? compensation;

  const CompensationFormScreen({
    super.key,
    required this.projectId,
    this.compensation,
  });

  @override
  State<CompensationFormScreen> createState() => _CompensationFormScreenState();
}

class _CompensationFormScreenState extends State<CompensationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService.instance;
  final _locationService = LocationService.instance;
  final _imageService = ImageService.instance;

  late TextEditingController _beneficiaireController;
  late TextEditingController _descriptionController;
  late TextEditingController _montantController;
  late TextEditingController _commentaireController;
  
  DateTime _selectedDate = DateTime.now();
  String _selectedTypeActif = 'terrain';
  String _selectedDevise = 'CDF';
  String _selectedStatut = 'En attente';
  List<String> _photos = [];
  double? _latitude;
  double? _longitude;
  String? _localisation;
  bool _isLoading = false;

  final List<String> _typesActif = [
    'terrain',
    'culture',
    'batiment',
    'arbre',
    'autre',
  ];

  final List<String> _devises = ['CDF', 'USD', 'EUR'];

  @override
  void initState() {
    super.initState();
    _beneficiaireController = TextEditingController();
    _descriptionController = TextEditingController();
    _montantController = TextEditingController();
    _commentaireController = TextEditingController();

    if (widget.compensation != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final data = widget.compensation!;
    _beneficiaireController.text = data['beneficiaire'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    _montantController.text = data['montant'].toString();
    _commentaireController.text = data['commentaire'] ?? '';
    _selectedDate = DateTime.parse(data['date']);
    _selectedTypeActif = data['typeActif'] ?? 'terrain';
    _selectedDevise = data['devise'] ?? 'CDF';
    _selectedStatut = data['statut'] ?? 'En attente';
    _latitude = data['latitude'];
    _longitude = data['longitude'];
    _localisation = data['localisation'];
    
    if (data['photos'] != null && data['photos'].isNotEmpty) {
      _photos = data['photos'].split(',');
    }
  }

  @override
  void dispose() {
    _beneficiaireController.dispose();
    _descriptionController.dispose();
    _montantController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

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
      setState(() => _isLoading = false);
    }
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

  Future<void> _saveCompensation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final compensation = Compensation(
        id: widget.compensation?['id'] ?? const Uuid().v4(),
        projectId: widget.projectId,
        date: _selectedDate,
        beneficiaire: _beneficiaireController.text,
        typeActif: _selectedTypeActif,
        description: _descriptionController.text,
        montant: double.parse(_montantController.text),
        devise: _selectedDevise,
        statut: _selectedStatut,
        localisation: _localisation,
        latitude: _latitude,
        longitude: _longitude,
        photos: _photos,
        commentaire: _commentaireController.text.isEmpty ? null : _commentaireController.text,
        createdAt: widget.compensation != null
            ? DateTime.parse(widget.compensation!['createdAt'])
            : DateTime.now(),
      );

      if (widget.compensation == null) {
        await _db.insert('compensations', compensation.toMap());
      } else {
        await _db.update('compensations', compensation.toMap(), compensation.id);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compensation enregistrée')),
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
        title: Text(widget.compensation == null ? 'Nouvelle Compensation' : 'Modifier Compensation'),
        backgroundColor: const Color(0xFFF57C00),
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
              onPressed: _saveCompensation,
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

            // Bénéficiaire
            TextFormField(
              controller: _beneficiaireController,
              decoration: const InputDecoration(
                labelText: 'Bénéficiaire *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le bénéficiaire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Type d'actif
            DropdownButtonFormField<String>(
              value: _selectedTypeActif,
              decoration: const InputDecoration(
                labelText: 'Type d\'actif',
                prefixIcon: Icon(Icons.category),
              ),
              items: _typesActif.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedTypeActif = value!);
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

            // Montant et Devise
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _montantController,
                    decoration: const InputDecoration(
                      labelText: 'Montant *',
                      prefixIcon: Icon(Icons.attach_money),
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
                    value: _selectedDevise,
                    decoration: const InputDecoration(
                      labelText: 'Devise',
                    ),
                    items: _devises.map((devise) {
                      return DropdownMenuItem(
                        value: devise,
                        child: Text(devise),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedDevise = value!);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Statut
            DropdownButtonFormField<String>(
              value: _selectedStatut,
              decoration: const InputDecoration(
                labelText: 'Statut',
                prefixIcon: Icon(Icons.flag),
              ),
              items: StatusOptions.compensationStatut.map((statut) {
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
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                onPressed: _isLoading ? null : _saveCompensation,
                icon: const Icon(Icons.save),
                label: Text(widget.compensation == null ? 'Enregistrer' : 'Mettre à jour'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
