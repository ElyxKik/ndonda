import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/database_service.dart';
import 'evenement_form_screen.dart';
import 'pges_form_screen.dart';
import 'personnel_form_screen.dart';
import 'compensation_form_screen.dart';
import 'consultation_form_screen.dart';
import 'dechet_form_screen.dart';
import 'incident_form_screen.dart';
import 'sensibilisation_form_screen.dart';
import 'equipement_form_screen.dart';
import 'contentieux_form_screen.dart';
import 'plainte_form_screen.dart';

class ModuleListScreen extends StatefulWidget {
  final ModuleInfo module;
  final String projectId;

  const ModuleListScreen({
    super.key,
    required this.module,
    required this.projectId,
  });

  @override
  State<ModuleListScreen> createState() => _ModuleListScreenState();
}

class _ModuleListScreenState extends State<ModuleListScreen> {
  final DatabaseService _db = DatabaseService.instance;
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tableName = _getTableName(widget.module.id);
      final data = await _db.query(
        tableName,
        where: 'projectId = ?',
        whereArgs: [widget.projectId],
        orderBy: 'createdAt DESC',
      );

      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getTableName(String moduleId) {
    switch (moduleId) {
      case 'evenements':
        return 'evenements';
      case 'pges':
        return 'pges_mesures';
      case 'personnel':
        return 'personnel';
      case 'compensation':
        return 'compensations';
      case 'consultation':
        return 'consultations';
      case 'dechets':
        return 'dechets';
      case 'incidents':
        return 'incidents';
      case 'sensibilisation':
        return 'sensibilisations';
      case 'equipements':
        return 'equipements';
      case 'contentieux':
        return 'contentieux';
      case 'plaintes':
        return 'plaintes';
      default:
        return 'evenements';
    }
  }

  void _navigateToForm({Map<String, dynamic>? item}) {
    Widget formScreen;

    switch (widget.module.id) {
      case 'evenements':
        formScreen = EvenementFormScreen(
          projectId: widget.projectId,
          evenement: item,
        );
        break;
      case 'pges':
        formScreen = PgesFormScreen(
          projectId: widget.projectId,
          mesure: item,
        );
        break;
      case 'personnel':
        formScreen = PersonnelFormScreen(
          projectId: widget.projectId,
          personnel: item,
        );
        break;
      case 'compensation':
        formScreen = CompensationFormScreen(
          projectId: widget.projectId,
          compensation: item,
        );
        break;
      case 'consultation':
        formScreen = ConsultationFormScreen(
          projectId: widget.projectId,
          consultation: item,
        );
        break;
      case 'dechets':
        formScreen = DechetFormScreen(
          projectId: widget.projectId,
          dechet: item,
        );
        break;
      case 'incidents':
        formScreen = IncidentFormScreen(
          projectId: widget.projectId,
          incident: item,
        );
        break;
      case 'sensibilisation':
        formScreen = SensibilisationFormScreen(
          projectId: widget.projectId,
          sensibilisation: item,
        );
        break;
      case 'equipements':
        formScreen = EquipementFormScreen(
          projectId: widget.projectId,
          equipement: item,
        );
        break;
      case 'contentieux':
        formScreen = ContentieuxFormScreen(
          projectId: widget.projectId,
          contentieux: item,
        );
        break;
      case 'plaintes':
        formScreen = PlainteFormScreen(
          projectId: widget.projectId,
          plainte: item,
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Formulaire en développement')),
        );
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => formScreen),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module.title),
        backgroundColor: widget.module.color,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.module.icon,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune donnée disponible',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Appuyez sur + pour ajouter',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _data.length,
                  itemBuilder: (context, index) {
                    final item = _data[index];
                    return _buildListItem(item);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        backgroundColor: widget.module.color,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: widget.module.color.withOpacity(0.2),
          child: Icon(
            widget.module.icon,
            color: widget.module.color,
          ),
        ),
        title: Text(
          _getItemTitle(item),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(_getItemSubtitle(item)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.info),
              onPressed: () => _navigateToForm(item: item),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: () => _confirmDelete(item['id']),
            ),
          ],
        ),
        onTap: () => _navigateToForm(item: item),
      ),
    );
  }

  String _getItemTitle(Map<String, dynamic> item) {
    switch (widget.module.id) {
      case 'evenements':
        return item['titre'] ?? 'Sans titre';
      case 'pges':
        return item['mesure'] ?? 'Sans mesure';
      case 'personnel':
        return '${item['categorie']} - ${item['nombreHommes'] + item['nombreFemmes']} personnes';
      default:
        return item['description'] ?? item['titre'] ?? 'Item';
    }
  }

  String _getItemSubtitle(Map<String, dynamic> item) {
    final date = DateTime.parse(item['date'] ?? item['createdAt']);
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cet élément ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db.delete(_getTableName(widget.module.id), id);
      _loadData();
    }
  }
}
