import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/equipement.dart';
import '../../services/database_service.dart';
import '../../services/image_service.dart';
import '../../utils/constants.dart';
import '../../widgets/photo_picker_widget.dart';

class EquipementFormScreen extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic>? equipement;

  const EquipementFormScreen({
    super.key,
    required this.projectId,
    this.equipement,
  });

  @override
  State<EquipementFormScreen> createState() => _EquipementFormScreenState();
}

class _EquipementFormScreenState extends State<EquipementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService.instance;
  final _imageService = ImageService.instance;

  late TextEditingController _designationController;
  late TextEditingController _quantiteDemandeeController;
  late TextEditingController _quantiteFournieController;
  late TextEditingController _fournisseurController;
  late TextEditingController _commentaireController;
  
  DateTime _selectedDate = DateTime.now();
  String _selectedTypeEquipement = 'EPI';
  String _selectedStatut = 'Demandé';
  List<String> _photos = [];
  bool _isLoading = false;

  final List<String> _typesEquipement = ['EPI', 'EPC'];

  @override
  void initState() {
    super.initState();
    _designationController = TextEditingController();
    _quantiteDemandeeController = TextEditingController(text: '0');
    _quantiteFournieController = TextEditingController(text: '0');
    _fournisseurController = TextEditingController();
    _commentaireController = TextEditingController();

    if (widget.equipement != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final data = widget.equipement!;
    _designationController.text = data['designation'] ?? '';
    _quantiteDemandeeController.text = data['quantiteDemandee'].toString();
    _quantiteFournieController.text = data['quantiteFournie'].toString();
    _fournisseurController.text = data['fournisseur'] ?? '';
    _commentaireController.text = data['commentaire'] ?? '';
    _selectedDate = DateTime.parse(data['date']);
    _selectedTypeEquipement = data['typeEquipement'] ?? 'EPI';
    _selectedStatut = data['statut'] ?? 'Demandé';
    
    if (data['photos'] != null && data['photos'].isNotEmpty) {
      _photos = data['photos'].split(',');
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

  Future<void> _addPhoto() async {
    final path = await _imageService.pickImageFromCamera();
    if (path != null) {
      setState(() => _photos.add(path));
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _saveEquipement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final equipement = Equipement(
        id: widget.equipement?['id'] ?? const Uuid().v4(),
        projectId: widget.projectId,
        date: _selectedDate,
        typeEquipement: _selectedTypeEquipement,
        designation: _designationController.text,
        quantiteDemandee: int.parse(_quantiteDemandeeController.text),
        quantiteFournie: int.parse(_quantiteFournieController.text),
        fournisseur: _fournisseurController.text.isEmpty ? null : _fournisseurController.text,
        statut: _selectedStatut,
        photos: _photos,
        commentaire: _commentaireController.text.isEmpty ? null : _commentaireController.text,
        createdAt: widget.equipement != null
            ? DateTime.parse(widget.equipement!['createdAt'])
            : DateTime.now(),
      );

      if (widget.equipement == null) {
        await _db.insert('equipements', equipement.toMap());
      } else {
        await _db.update('equipements', equipement.toMap(), equipement.id);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Équipement enregistré')),
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
        title: Text(widget.equipement == null ? 'Nouvel Équipement' : 'Modifier Équipement'),
        backgroundColor: const Color(0xFF303F9F),
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

            // Type d'équipement
            DropdownButtonFormField<String>(
              value: _selectedTypeEquipement,
              decoration: const InputDecoration(
                labelText: 'Type d\'équipement',
                prefixIcon: Icon(Icons.category),
                helperText: 'EPI: Équipement de Protection Individuelle\nEPC: Équipement de Protection Collective',
              ),
              items: _typesEquipement.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedTypeEquipement = value!);
              },
            ),
            const SizedBox(height: 16),

            // Désignation
            TextFormField(
              controller: _designationController,
              decoration: const InputDecoration(
                labelText: 'Désignation *',
                prefixIcon: Icon(Icons.label),
                hintText: 'Ex: Casque, Gants, Extincteur...',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer la désignation';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Quantité demandée
            TextFormField(
              controller: _quantiteDemandeeController,
              decoration: const InputDecoration(
                labelText: 'Quantité demandée *',
                prefixIcon: Icon(Icons.shopping_cart),
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

            // Quantité fournie
            TextFormField(
              controller: _quantiteFournieController,
              decoration: const InputDecoration(
                labelText: 'Quantité fournie',
                prefixIcon: Icon(Icons.inventory),
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

            // Statut
            DropdownButtonFormField<String>(
              value: _selectedStatut,
              decoration: const InputDecoration(
                labelText: 'Statut',
                prefixIcon: Icon(Icons.flag),
              ),
              items: StatusOptions.equipementStatut.map((statut) {
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

            // Fournisseur
            TextFormField(
              controller: _fournisseurController,
              decoration: const InputDecoration(
                labelText: 'Fournisseur',
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),

            // Résumé
            Card(
              color: AppColors.accent.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Résumé',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Demandé:'),
                        Text(
                          _quantiteDemandeeController.text,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Fourni:'),
                        Text(
                          _quantiteFournieController.text,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Manquant:'),
                        Text(
                          '${(int.tryParse(_quantiteDemandeeController.text) ?? 0) - (int.tryParse(_quantiteFournieController.text) ?? 0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: (int.tryParse(_quantiteDemandeeController.text) ?? 0) > (int.tryParse(_quantiteFournieController.text) ?? 0)
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                onPressed: _isLoading ? null : _saveEquipement,
                icon: const Icon(Icons.save),
                label: Text(widget.equipement == null ? 'Enregistrer' : 'Mettre à jour'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
