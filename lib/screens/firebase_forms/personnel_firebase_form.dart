import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class PersonnelFirebaseForm extends StatefulWidget {
  final String projectId;
  final String? personnelId;
  final Map<String, dynamic>? personnelData;

  const PersonnelFirebaseForm({
    super.key,
    required this.projectId,
    this.personnelId,
    this.personnelData,
  });

  @override
  State<PersonnelFirebaseForm> createState() =>
      _PersonnelFirebaseFormState();
}

class _PersonnelFirebaseFormState extends State<PersonnelFirebaseForm> {
  final _formKey = GlobalKey<FormState>();
  final _firebase = FirebaseService.instance;
  final _auth = AuthService.instance;

  // Controllers
  late TextEditingController _numeroController;
  late TextEditingController _expatFController;
  late TextEditingController _expatHController;
  late TextEditingController _locauxFController;
  late TextEditingController _locauxHController;
  late TextEditingController _nationauxFController;
  late TextEditingController _nationauxHController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    if (widget.personnelData != null) {
      _loadExistingData();
    }
  }

  void _initControllers() {
    _numeroController = TextEditingController(text: '0');
    _expatFController = TextEditingController(text: '0');
    _expatHController = TextEditingController(text: '0');
    _locauxFController = TextEditingController(text: '0');
    _locauxHController = TextEditingController(text: '0');
    _nationauxFController = TextEditingController(text: '0');
    _nationauxHController = TextEditingController(text: '0');
  }

  void _loadExistingData() {
    final data = widget.personnelData!;
    _numeroController.text = (data['numero'] ?? 0).toString();
    _expatFController.text = (data['expatF'] ?? 0).toString();
    _expatHController.text = (data['expatH'] ?? 0).toString();
    _locauxFController.text = (data['locauxF'] ?? 0).toString();
    _locauxHController.text = (data['locauxH'] ?? 0).toString();
    _nationauxFController.text = (data['nationauxF'] ?? 0).toString();
    _nationauxHController.text = (data['nationauxH'] ?? 0).toString();
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _expatFController.dispose();
    _expatHController.dispose();
    _locauxFController.dispose();
    _locauxHController.dispose();
    _nationauxFController.dispose();
    _nationauxHController.dispose();
    super.dispose();
  }

  int _calculateTotal() {
    return (int.tryParse(_expatFController.text) ?? 0) +
        (int.tryParse(_expatHController.text) ?? 0) +
        (int.tryParse(_locauxFController.text) ?? 0) +
        (int.tryParse(_locauxHController.text) ?? 0) +
        (int.tryParse(_nationauxFController.text) ?? 0) +
        (int.tryParse(_nationauxHController.text) ?? 0);
  }

  Future<void> _savePersonnel() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final personnelId = widget.personnelId ?? const Uuid().v4();

      final data = {
        'projectId': widget.projectId,
        'numero': int.tryParse(_numeroController.text) ?? 0,
        'expatF': int.tryParse(_expatFController.text) ?? 0,
        'expatH': int.tryParse(_expatHController.text) ?? 0,
        'locauxF': int.tryParse(_locauxFController.text) ?? 0,
        'locauxH': int.tryParse(_locauxHController.text) ?? 0,
        'nationauxF': int.tryParse(_nationauxFController.text) ?? 0,
        'nationauxH': int.tryParse(_nationauxHController.text) ?? 0,
        'total': _calculateTotal(),
        'updatedAt': now.toIso8601String(),
        'createdBy': _auth.currentUserId ?? 'anonymous',
      };

      if (widget.personnelId == null) {
        data['id'] = personnelId;
        data['createdAt'] = now.toIso8601String();
        await _firebase.setDocument('personnel', personnelId, data);
      } else {
        await _firebase.updateDocument('personnel', widget.personnelId!, data);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.personnelId == null
                ? 'Personnel enregistré avec succès'
                : 'Personnel mis à jour'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    Color? iconColor,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: iconColor),
        border: const OutlineInputBorder(),
        suffixText: 'pers.',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (value) {
        setState(() {}); // Recalculer le total
      },
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          if (int.tryParse(value) == null) {
            return 'Nombre invalide';
          }
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _calculateTotal();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.personnelId == null
            ? 'Nouveau Relevé Personnel'
            : 'Modifier Personnel'),
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
              onPressed: _savePersonnel,
              tooltip: 'Enregistrer',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Numéro
            TextFormField(
              controller: _numeroController,
              decoration: const InputDecoration(
                labelText: 'Numéro',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 24),

            // Section Expatriés
            const Text(
              'Expatriés',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildNumberField(
              controller: _expatFController,
              label: 'Expatrié Femme',
              icon: Icons.person,
              iconColor: Colors.pink,
            ),
            const SizedBox(height: 16),
            _buildNumberField(
              controller: _expatHController,
              label: 'Expatrié Homme',
              icon: Icons.person,
              iconColor: Colors.blue,
            ),
            const SizedBox(height: 24),

            // Section Locaux
            const Text(
              'Locaux',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildNumberField(
              controller: _locauxFController,
              label: 'Locaux Femme',
              icon: Icons.person_outline,
              iconColor: Colors.pink,
            ),
            const SizedBox(height: 16),
            _buildNumberField(
              controller: _locauxHController,
              label: 'Locaux Homme',
              icon: Icons.person_outline,
              iconColor: Colors.blue,
            ),
            const SizedBox(height: 24),

            // Section Nationaux
            const Text(
              'Nationaux',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildNumberField(
              controller: _nationauxFController,
              label: 'Nationaux Femme',
              icon: Icons.groups,
              iconColor: Colors.pink,
            ),
            const SizedBox(height: 16),
            _buildNumberField(
              controller: _nationauxHController,
              label: 'Nationaux Homme',
              icon: Icons.groups,
              iconColor: Colors.blue,
            ),
            const SizedBox(height: 24),

            // Total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Personnel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$total personnes',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bouton Enregistrer
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _savePersonnel,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Enregistrement...' : 'Enregistrer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
