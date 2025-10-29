import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class EvenementChantierFirebaseForm extends StatefulWidget {
  final String projectId;
  final String? evenementId;
  final Map<String, dynamic>? evenementData;

  const EvenementChantierFirebaseForm({
    super.key,
    required this.projectId,
    this.evenementId,
    this.evenementData,
  });

  @override
  State<EvenementChantierFirebaseForm> createState() =>
      _EvenementChantierFirebaseFormState();
}

class _EvenementChantierFirebaseFormState
    extends State<EvenementChantierFirebaseForm> {
  final _formKey = GlobalKey<FormState>();
  final _firebase = FirebaseService.instance;
  final _auth = AuthService.instance;

  // Controllers
  late TextEditingController _activiteSourceController;
  late TextEditingController _composantController;
  late TextEditingController _constatController;
  late TextEditingController _mesureController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    if (widget.evenementData != null) {
      _loadExistingData();
    }
  }

  void _initControllers() {
    _activiteSourceController = TextEditingController();
    _composantController = TextEditingController();
    _constatController = TextEditingController();
    _mesureController = TextEditingController();
  }

  void _loadExistingData() {
    final data = widget.evenementData!;
    _activiteSourceController.text = data['activiteSource'] ?? '';
    _composantController.text = data['composant'] ?? '';
    _constatController.text = data['constat'] ?? '';
    _mesureController.text = data['mesure'] ?? '';
  }

  @override
  void dispose() {
    _activiteSourceController.dispose();
    _composantController.dispose();
    _constatController.dispose();
    _mesureController.dispose();
    super.dispose();
  }

  Future<void> _saveEvenement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final evenementId = widget.evenementId ?? const Uuid().v4();

      final data = {
        'projectId': widget.projectId,
        'activiteSource': _activiteSourceController.text.trim(),
        'composant': _composantController.text.trim(),
        'constat': _constatController.text.trim(),
        'mesure': _mesureController.text.trim(),
        'updatedAt': now.toIso8601String(),
        'createdBy': _auth.currentUserId ?? 'anonymous',
      };

      if (widget.evenementId == null) {
        data['id'] = evenementId;
        data['createdAt'] = now.toIso8601String();
        await _firebase.setDocument('evenementChantier', evenementId, data);
      } else {
        await _firebase.updateDocument(
            'evenementChantier', widget.evenementId!, data);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.evenementId == null
                ? 'Événement enregistré avec succès'
                : 'Événement mis à jour'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.evenementId == null
            ? 'Nouvel Événement Chantier'
            : 'Modifier Événement'),
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
              onPressed: _saveEvenement,
              tooltip: 'Enregistrer',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Activité Source
            TextFormField(
              controller: _activiteSourceController,
              decoration: const InputDecoration(
                labelText: 'Activité Source *',
                hintText: 'Décrivez l\'activité source',
                prefixIcon: Icon(Icons.source),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'L\'activité source est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Composant
            TextFormField(
              controller: _composantController,
              decoration: const InputDecoration(
                labelText: 'Composant *',
                hintText: 'Composant concerné',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le composant est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Constat
            TextFormField(
              controller: _constatController,
              decoration: const InputDecoration(
                labelText: 'Constat *',
                hintText: 'Décrivez le constat',
                prefixIcon: Icon(Icons.visibility),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le constat est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Mesure
            TextFormField(
              controller: _mesureController,
              decoration: const InputDecoration(
                labelText: 'Mesure *',
                hintText: 'Mesures prises ou à prendre',
                prefixIcon: Icon(Icons.rule),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La mesure est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Bouton Enregistrer
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveEvenement,
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
