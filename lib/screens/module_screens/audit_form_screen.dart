import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/audit.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../../services/image_service.dart';
import '../../utils/constants.dart';
import '../../widgets/photo_picker_widget.dart';

class AuditFormScreen extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic>? audit;

  const AuditFormScreen({
    super.key,
    required this.projectId,
    this.audit,
  });

  @override
  State<AuditFormScreen> createState() => _AuditFormScreenState();
}

class _AuditFormScreenState extends State<AuditFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService.instance;
  final _locationService = LocationService.instance;
  final _imageService = ImageService.instance;

  late TextEditingController _titreController;
  late TextEditingController _responsableController;
  late TextEditingController _observationsController;
  
  DateTime _selectedDate = DateTime.now();
  String _selectedStatut = 'interne';
  List<String> _photos = [];
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;

  final List<String> _statuts = ['interne', 'externe', 'supervision'];

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController();
    _responsableController = TextEditingController();
    _observationsController = TextEditingController();
    if (widget.audit != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final data = widget.audit!;
    _titreController.text = data['titre'] ?? '';
    _responsableController.text = data['responsable'] ?? '';
    _observationsController.text = data['observations'] ?? '';
    _selectedDate = DateTime.parse(data['date']);
    _selectedStatut = data['statut'] ?? 'interne';
    _latitude = data['latitude'];
    _longitude = data['longitude'];
    if (data['photos'] != null && data['photos'].isNotEmpty) {
      _photos = data['photos'].split(',');
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _responsableController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
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

  Future<void> _saveAudit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final audit = Audit(
        id: widget.audit?['id'] ?? const Uuid().v4(),
        projectId: widget.projectId,
        date: _selectedDate,
        statut: _selectedStatut,
        titre: _titreController.text,
        responsable: _responsableController.text,
        observations: _observationsController.text.isEmpty ? null : _observationsController.text,
        photos: _photos,
        latitude: _latitude,
        longitude: _longitude,
        createdAt: widget.audit != null
            ? DateTime.parse(widget.audit!['createdAt'])
            : DateTime.now(),
      );

      if (widget.audit == null) {
        await _db.insert('audits', audit.toMap());
      } else {
        await _db.update('audits', audit.toMap(), audit.id);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audit enregistré')),
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
        title: Text(widget.audit == null ? 'Nouvel Audit' : 'Modifier Audit'),
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
              onPressed: _saveAudit,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                    setState(() => _selectedDate = date);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStatut,
              decoration: const InputDecoration(
                labelText: 'Type d\'Audit',
                prefixIcon: Icon(Icons.category),
              ),
              items: _statuts.map((statut) {
                return DropdownMenuItem(
                  value: statut,
                  child: Text(statut.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedStatut = value!);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titreController,
              decoration: const InputDecoration(
                labelText: 'Titre de l\'audit *',
                prefixIcon: Icon(Icons.title),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le titre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
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
            PhotoPickerWidget(
              photos: _photos,
              onAddPhoto: _addPhoto,
              onRemovePhoto: _removePhoto,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observationsController,
              decoration: const InputDecoration(
                labelText: 'Observations',
                prefixIcon: Icon(Icons.comment),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveAudit,
                icon: const Icon(Icons.save),
                label: Text(widget.audit == null ? 'Enregistrer' : 'Mettre à jour'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
