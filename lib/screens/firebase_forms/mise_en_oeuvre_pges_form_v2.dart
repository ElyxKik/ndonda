import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';

class MiseEnOeuvrePGESFormV2 extends StatefulWidget {
  final String projectId;
  final String? documentId;
  final Map<String, dynamic>? data;

  const MiseEnOeuvrePGESFormV2({
    super.key,
    required this.projectId,
    this.documentId,
    this.data,
  });

  @override
  State<MiseEnOeuvrePGESFormV2> createState() => _MiseEnOeuvrePGESFormV2State();
}

class _MiseEnOeuvrePGESFormV2State extends State<MiseEnOeuvrePGESFormV2> {
  final _firebase = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  late ScrollController _scrollController;

  // Liste des 30 indicateurs
  final List<String> indicators = [
    'Nettoyage régulier du chantier',
    'Réglementation de la vitesse de circulation des véhicules',
    'Aménagement du site d\'entreposage des matériaux de Déblais',
    'Contrôle régulier des engins et véhicules du chantier',
    'Contrôle de niveau De déversement de lubrifiant et carburant par terre',
    'Remise en état du site perturbé après utilisation',
    'La signature d\'un Contrat à durée déterminée pour tout agent affecté au chantier',
    'Mise en place des panneaux de signalisation',
    'Signature d\'une convention avec un Centre hospitalier de la place',
    'Aménagement des latrines',
    'Cloisonnement des sites des travaux',
    'Fourniture des Equipements de Protection Individuelle',
    'Entretien régulier des installations du chantier',
    'Interdiction formelle à toute personne étrangère et véhicules étrangers d\'accéder',
    'Administration d\'un vaccin Antitétanique',
    'Mise en place des dispositions anti-incendie (extincteurs)',
    'Sensibilisation du Personnel sur les IST/VIH SIDA',
    'Distribution de l\'eau potable aux ouvriers',
    'Mise en place des poubelles',
    'Eclairage des sites et surveillance',
    'Gestion des déchets',
    'Evacuation des déchets',
    'Port des EPI',
    'Gestion des conflits',
    'Information à la population',
    'Accident',
    'Abattage d\'arbres',
    'Indemnisation',
    'Protection des eaux',
    'Protection de l\'air',
  ];

  late Map<int, String> _realizationStatus; // Oui/Non pour chaque indicateur
  late Map<int, TextEditingController> _actionControllers; // Action prise pour chaque indicateur

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    _realizationStatus = {};
    _actionControllers = {};

    // Initialiser les contrôleurs
    for (int i = 0; i < indicators.length; i++) {
      _realizationStatus[i] = 'Non';
      _actionControllers[i] = TextEditingController();
    }

    // Charger les données existantes si disponibles
    if (widget.data != null) {
      final indicators = widget.data!['indicators'] as List? ?? [];
      for (int i = 0; i < indicators.length && i < this.indicators.length; i++) {
        final indicator = indicators[i] as Map<String, dynamic>? ?? {};
        _realizationStatus[i] = indicator['realise'] ?? 'Non';
        _actionControllers[i]?.text = indicator['actionPrise'] ?? '';
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var controller in _actionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveData() async {
    if (_formKey.currentState!.validate()) {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur non connecté')),
        );
        return;
      }

      try {
        // Préparer les données des indicateurs
        List<Map<String, dynamic>> indicatorsData = [];
        for (int i = 0; i < indicators.length; i++) {
          indicatorsData.add({
            'name': indicators[i],
            'realise': _realizationStatus[i] ?? 'Non',
            'actionPrise': _actionControllers[i]?.text ?? '',
          });
        }

        final data = {
          'projectId': widget.projectId,
          'indicators': indicatorsData,
          'createdBy': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (widget.documentId != null) {
          // Mise à jour
          await _firebase
              .collection('mise_en_oeuvre_pges')
              .doc(widget.documentId)
              .update(data);
        } else {
          // Création
          await _firebase.collection('mise_en_oeuvre_pges').add(data);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Données enregistrées avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mise en oeuvre PGES'),
        backgroundColor: AppColors.primary,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Indicateurs PGES',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(
                indicators.length,
                (index) => _buildIndicatorCard(index),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveData,
                  icon: const Icon(Icons.save),
                  label: const Text('Enregistrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicatorCard(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre de l'indicateur
            Text(
              '${index + 1}. ${indicators[index]}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            // Boutons Oui/Non
            Row(
              children: [
                const Text(
                  'Réalisé:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _realizationStatus[index] = 'Oui';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _realizationStatus[index] == 'Oui'
                                  ? AppColors.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: _realizationStatus[index] == 'Oui'
                                    ? AppColors.primary
                                    : Colors.grey[300]!,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Oui',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _realizationStatus[index] == 'Oui'
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _realizationStatus[index] = 'Non';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _realizationStatus[index] == 'Non'
                                  ? Colors.orange
                                  : Colors.transparent,
                              border: Border.all(
                                color: _realizationStatus[index] == 'Non'
                                    ? Colors.orange
                                    : Colors.grey[300]!,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Non',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _realizationStatus[index] == 'Non'
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Champ Action prise
            TextFormField(
              controller: _actionControllers[index],
              decoration: InputDecoration(
                labelText: 'Action prise',
                hintText: 'Décrivez l\'action prise',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.edit, color: AppColors.primary),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
