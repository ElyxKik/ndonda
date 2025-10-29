import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/constants.dart';

class HSEIndicatorsScreen extends StatefulWidget {
  final String projectId;

  const HSEIndicatorsScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<HSEIndicatorsScreen> createState() => _HSEIndicatorsScreenState();
}

class _HSEIndicatorsScreenState extends State<HSEIndicatorsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  // Section 1 : Informations générales
  late TextEditingController _responsableHSEController;
  late TextEditingController _zoneController;
  String _selectedMonth = 'Janvier';
  DateTime? _selectedDate;

  // Section 2 : Indicateurs environnementaux
  final Map<String, String> _environmentalIndicators = {
    'Nettoyage régulier du chantier': 'Non',
    'Réglementation de la vitesse': 'Non',
    'Aménagement du site d\'entreposage': 'Non',
    'Contrôle des engins et véhicules': 'Non',
    'Contrôle des déversements': 'Non',
    'Remise en état du site perturbé': 'Non',
    'Mise en place des panneaux de signalisation': 'Non',
    'Gestion des déchets': 'Non',
    'Protection des eaux et de l\'air': 'Non',
  };

  // Section 3 : Indicateurs sociaux et de santé
  final Map<String, String> _socialIndicators = {
    'Signature de contrats pour les agents': 'Non',
    'Convention avec un centre hospitalier': 'Non',
    'Distribution d\'eau potable': 'Non',
    'Aménagement des latrines': 'Non',
    'Port des EPI': 'Non',
    'Sensibilisation IST/VIH/SIDA': 'Non',
    'Gestion des conflits': 'Non',
    'Information à la population': 'Non',
  };

  // Section 4 : Indicateurs quantitatifs
  final Map<String, TextEditingController> _quantitativeIndicators = {};

  // Section 5 : Observations
  late TextEditingController _observationsController;

  final List<String> _months = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  final List<String> _options = ['Oui', 'Non', 'Partiel', 'N.A'];

  final List<String> _quantitativeFields = [
    'Nombre de formations/sensibilisations',
    'Nombre d\'accidents',
    'Nombre de cas de maladie avec arrêt',
    'Nombre d\'inspections',
    'Nombre de non-conformités',
    'Nombre de plaintes et solutions',
    'Nombre d\'EPI distribués',
    'Nombre de visites médicales',
    'Nombre de jours sans accident',
    'Nombre de femmes employées',
    'Nombre d\'hommes employés',
    'Nombre total de personnes',
    'Nombre d\'expatriés',
    'Nombre de nationaux',
  ];

  @override
  void initState() {
    super.initState();
    _responsableHSEController = TextEditingController();
    _zoneController = TextEditingController();
    _observationsController = TextEditingController();
    
    for (var field in _quantitativeFields) {
      _quantitativeIndicators[field] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _responsableHSEController.dispose();
    _zoneController.dispose();
    _observationsController.dispose();
    for (var controller in _quantitativeIndicators.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final data = {
        'projectId': widget.projectId,
        'createdBy': _auth.currentUser?.uid, // Aligné avec les règles de sécurité
        'createdAt': FieldValue.serverTimestamp(),
        'responsableHSE': _responsableHSEController.text,
        'mois': _selectedMonth,
        'zone': _zoneController.text,
        'dateSubmission': _selectedDate,
        'environmentalIndicators': _environmentalIndicators,
        'socialIndicators': _socialIndicators,
        'quantitativeIndicators': {
          for (var entry in _quantitativeIndicators.entries)
            entry.key: int.tryParse(entry.value.text) ?? 0
        },
        'observations': _observationsController.text,
      };

      await _firestore.collection('hseIndicators').add(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Indicateurs HSE enregistrés avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Indicateurs HSE'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1
              _buildSectionHeader('Section 1 : Informations Générales'),
              _buildTextField(
                controller: _responsableHSEController,
                label: 'Nom du responsable HSE',
                icon: Icons.person,
              ),
              const SizedBox(height: 12),
              _buildMonthDropdown(),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _zoneController,
                label: 'Zone ou site concerné',
                icon: Icons.location_on,
              ),
              const SizedBox(height: 12),
              _buildDatePicker(),
              const SizedBox(height: 24),

              // Section 2
              _buildSectionHeader('Section 2 : Indicateurs Environnementaux'),
              ..._buildIndicatorsList(_environmentalIndicators),
              const SizedBox(height: 24),

              // Section 3
              _buildSectionHeader('Section 3 : Indicateurs Sociaux et de Santé'),
              ..._buildIndicatorsList(_socialIndicators),
              const SizedBox(height: 24),

              // Section 4
              _buildSectionHeader('Section 4 : Indicateurs Quantitatifs'),
              ..._buildQuantitativeFields(),
              const SizedBox(height: 24),

              // Section 5
              _buildSectionHeader('Section 5 : Observations Complémentaires'),
              _buildTextAreaField(
                controller: _observationsController,
                label: 'Commentaires ou observations terrain',
              ),
              const SizedBox(height: 24),

              // Bouton de soumission
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.save),
                  label: const Text('Enregistrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF263238),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Ce champ est requis';
        return null;
      },
    );
  }

  Widget _buildTextAreaField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildMonthDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedMonth,
      decoration: InputDecoration(
        labelText: 'Mois de suivi',
        prefixIcon: const Icon(Icons.calendar_month, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      items: _months.map((month) {
        return DropdownMenuItem(value: month, child: Text(month));
      }).toList(),
      onChanged: (value) {
        if (value != null) setState(() => _selectedMonth = value);
      },
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              _selectedDate != null
                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                  : 'Date de soumission',
              style: TextStyle(
                color: _selectedDate != null ? Colors.black : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildIndicatorsList(Map<String, String> indicators) {
    return indicators.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _options.map((option) {
                  final isSelected = entry.value == option;
                  return ChoiceChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => indicators[entry.key] = option);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildQuantitativeFields() {
    return _quantitativeFields.map((field) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: _quantitativeIndicators[field],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: field,
            prefixIcon: const Icon(Icons.numbers, color: AppColors.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      );
    }).toList();
  }
}
