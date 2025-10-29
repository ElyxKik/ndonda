import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';

class ActivityReportForm extends StatefulWidget {
  final String projectId;

  const ActivityReportForm({Key? key, required this.projectId}) : super(key: key);

  @override
  _ActivityReportFormState createState() => _ActivityReportFormState();
}

class _ActivityReportFormState extends State<ActivityReportForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  String _status = 'en_cours';
  final List<TextEditingController> _activityControllers = [TextEditingController()];

  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != (isStart ? _startDate : _endDate)) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _addActivityField() {
    setState(() {
      _activityControllers.add(TextEditingController());
    });
  }

  void _removeActivityField(int index) {
    setState(() {
      _activityControllers.removeAt(index).dispose();
    });
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur non connecté.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      try {
        final activities = _activityControllers
            .map((controller) => controller.text)
            .where((text) => text.isNotEmpty)
            .toList();

        await FirebaseFirestore.instance.collection('activityReports').add({
          'projectId': widget.projectId,
          'title': _titleController.text,
          'description': _descriptionController.text,
          'startDate': Timestamp.fromDate(_startDate),
          'endDate': Timestamp.fromDate(_endDate),
          'status': _status,
          'activities': activities,
          'statistics': {},
          'createdBy': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
        );
      } finally {
        if (mounted) {
           setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var controller in _activityControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Rapport d\'Activité'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Titre du Rapport'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un titre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(labelText: 'Statut'),
                      items: ['en_cours', 'termine', 'en_attente']
                          .map((label) => DropdownMenuItem(
                                child: Text(label),
                                value: label,
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _status = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Date de début: ${DateFormat('dd/MM/yyyy').format(_startDate)}'),
                        ),
                        TextButton(
                          onPressed: () => _selectDate(context, true),
                          child: const Text('Sélectionner'),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Date de fin: ${DateFormat('dd/MM/yyyy').format(_endDate)}'),
                        ),
                        TextButton(
                          onPressed: () => _selectDate(context, false),
                          child: const Text('Sélectionner'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Activités Réalisées', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ..._buildActivityFields(),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter une activité'),
                      onPressed: _addActivityField,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveForm,
                      child: const Text('Enregistrer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildActivityFields() {
    return List.generate(_activityControllers.length, (index) {
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _activityControllers[index],
              decoration: InputDecoration(labelText: 'Activité #${index + 1}'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: () => _removeActivityField(index),
          ),
        ],
      );
    });
  }
}
