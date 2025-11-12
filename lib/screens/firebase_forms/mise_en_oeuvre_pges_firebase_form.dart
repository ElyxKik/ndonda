import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';

class MiseEnOeuvreFirebaseForm extends StatefulWidget {
  final String projectId;
  final String? documentId;
  final Map<String, dynamic>? data;

  const MiseEnOeuvreFirebaseForm({
    super.key,
    required this.projectId,
    this.documentId,
    this.data,
  });

  @override
  State<MiseEnOeuvreFirebaseForm> createState() => _MiseEnOeuvreFirebaseFormState();
}

class _MiseEnOeuvreFirebaseFormState extends State<MiseEnOeuvreFirebaseForm> {
  final _firebase = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _actionPriseController;
  String _realise = 'Non';

  @override
  void initState() {
    super.initState();
    _actionPriseController = TextEditingController(text: widget.data?['actionPrise'] ?? '');
    
    // Gérer le cas où realise pourrait être un Timestamp ou une String
    final realiseValue = widget.data?['realise'];
    if (realiseValue is String) {
      _realise = realiseValue;
    } else {
      _realise = 'Non';
    }
  }

  @override
  void dispose() {
    _actionPriseController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final data = {
        'projectId': widget.projectId,
        'actionPrise': _actionPriseController.text,
        'realise': _realise,
        'createdBy': _auth.currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.documentId == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await _firebase.collection('mise_en_oeuvre_pges').add(data);
      } else {
        await _firebase.collection('mise_en_oeuvre_pges').doc(widget.documentId).update(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.documentId == null ? 'Document créé' : 'Document modifié'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteData() async {
    if (widget.documentId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce document ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firebase.collection('mise_en_oeuvre_pges').doc(widget.documentId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document supprimé'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.documentId == null ? 'Nouvelle mise en oeuvre' : 'Modifier'),
        backgroundColor: AppColors.primary,
        actions: [
          if (widget.documentId != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteData,
              tooltip: 'Supprimer',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre de la section
              Text(
                'Mise en oeuvre PGES',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Champ Action prise
              TextFormField(
                controller: _actionPriseController,
                decoration: InputDecoration(
                  labelText: 'Action prise',
                  hintText: 'Décrivez l\'action prise',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.assignment, color: AppColors.primary),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 4,
                validator: (value) => value?.isEmpty ?? true ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: 24),

              // Champ Réalisé (Oui/Non)
              Text(
                'Réalisé',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _realise = 'Oui'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _realise == 'Oui' ? AppColors.primary : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Oui',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _realise == 'Oui' ? Colors.white : AppColors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _realise = 'Non'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _realise == 'Non' ? AppColors.primary : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Non',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _realise == 'Non' ? Colors.white : AppColors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Bouton Enregistrer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveData,
                  icon: const Icon(Icons.save, size: 20),
                  label: const Text(
                    'Enregistrer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
