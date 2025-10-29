import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/personnel.dart';
import '../../services/database_service.dart';
import '../../utils/constants.dart';

class PersonnelFormScreen extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic>? personnel;

  const PersonnelFormScreen({
    super.key,
    required this.projectId,
    this.personnel,
  });

  @override
  State<PersonnelFormScreen> createState() => _PersonnelFormScreenState();
}

class _PersonnelFormScreenState extends State<PersonnelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService.instance;

  late TextEditingController _nombreHommesController;
  late TextEditingController _nombreFemmesController;
  late TextEditingController _nationaliteController;
  late TextEditingController _fonctionController;
  late TextEditingController _commentaireController;
  
  DateTime _selectedPeriode = DateTime.now();
  String _selectedCategorie = 'cadres';
  bool _isLoading = false;

  final List<String> _categories = [
    'cadres',
    'techniciens',
    'ouvriers',
    'autres',
  ];

  @override
  void initState() {
    super.initState();
    _nombreHommesController = TextEditingController(text: '0');
    _nombreFemmesController = TextEditingController(text: '0');
    _nationaliteController = TextEditingController();
    _fonctionController = TextEditingController();
    _commentaireController = TextEditingController();

    if (widget.personnel != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final data = widget.personnel!;
    _nombreHommesController.text = data['nombreHommes'].toString();
    _nombreFemmesController.text = data['nombreFemmes'].toString();
    _nationaliteController.text = data['nationalite'] ?? '';
    _fonctionController.text = data['fonction'] ?? '';
    _commentaireController.text = data['commentaire'] ?? '';
    _selectedPeriode = DateTime.parse(data['periode']);
    _selectedCategorie = data['categorie'] ?? 'cadres';
  }

  @override
  void dispose() {
    _nombreHommesController.dispose();
    _nombreFemmesController.dispose();
    _nationaliteController.dispose();
    _fonctionController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _savePersonnel() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final personnel = Personnel(
        id: widget.personnel?['id'] ?? const Uuid().v4(),
        projectId: widget.projectId,
        periode: _selectedPeriode,
        categorie: _selectedCategorie,
        nombreHommes: int.parse(_nombreHommesController.text),
        nombreFemmes: int.parse(_nombreFemmesController.text),
        nationalite: _nationaliteController.text.isEmpty ? null : _nationaliteController.text,
        fonction: _fonctionController.text.isEmpty ? null : _fonctionController.text,
        commentaire: _commentaireController.text.isEmpty ? null : _commentaireController.text,
        createdAt: widget.personnel != null
            ? DateTime.parse(widget.personnel!['createdAt'])
            : DateTime.now(),
      );

      if (widget.personnel == null) {
        await _db.insert('personnel', personnel.toMap());
      } else {
        await _db.update('personnel', personnel.toMap(), personnel.id);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Personnel enregistré')),
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
        title: Text(widget.personnel == null ? 'Nouveau Personnel' : 'Modifier Personnel'),
        backgroundColor: const Color(0xFF7B1FA2),
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
              onPressed: _savePersonnel,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Période
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                title: const Text('Période'),
                subtitle: Text(
                  '${_selectedPeriode.month}/${_selectedPeriode.year}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedPeriode,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedPeriode = date;
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
                  child: Text(cat.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategorie = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Nombre Hommes
            TextFormField(
              controller: _nombreHommesController,
              decoration: const InputDecoration(
                labelText: 'Nombre d\'hommes *',
                prefixIcon: Icon(Icons.man),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le nombre';
                }
                if (int.tryParse(value) == null) {
                  return 'Veuillez entrer un nombre valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Nombre Femmes
            TextFormField(
              controller: _nombreFemmesController,
              decoration: const InputDecoration(
                labelText: 'Nombre de femmes *',
                prefixIcon: Icon(Icons.woman),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le nombre';
                }
                if (int.tryParse(value) == null) {
                  return 'Veuillez entrer un nombre valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Total
            Card(
              color: AppColors.accent.withOpacity(0.1),
              child: ListTile(
                leading: const Icon(Icons.people, color: AppColors.primary),
                title: const Text('Total'),
                trailing: Text(
                  '${(int.tryParse(_nombreHommesController.text) ?? 0) + (int.tryParse(_nombreFemmesController.text) ?? 0)} personnes',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nationalité
            TextFormField(
              controller: _nationaliteController,
              decoration: const InputDecoration(
                labelText: 'Nationalité',
                prefixIcon: Icon(Icons.flag),
              ),
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
                onPressed: _isLoading ? null : _savePersonnel,
                icon: const Icon(Icons.save),
                label: Text(widget.personnel == null ? 'Enregistrer' : 'Mettre à jour'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
