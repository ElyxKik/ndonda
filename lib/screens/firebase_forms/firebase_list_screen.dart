import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../providers/app_provider.dart';
import '../../utils/constants.dart';

class FirebaseListScreen extends StatefulWidget {
  final String projectId;
  final String? projectName;
  final String collectionName;
  final String title;
  final IconData icon;
  final Widget Function(String projectId, {String? documentId, Map<String, dynamic>? data}) formBuilder;

  const FirebaseListScreen({
    super.key,
    required this.projectId,
    this.projectName,
    required this.collectionName,
    required this.title,
    required this.icon,
    required this.formBuilder,
  });

  @override
  State<FirebaseListScreen> createState() => _FirebaseListScreenState();
}

class _FirebaseListScreenState extends State<FirebaseListScreen> {
  final _firebase = FirebaseService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18),
            ),
            if (widget.projectName != null)
              Text(
                widget.projectName!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
              ),
          ],
        ),
        backgroundColor: AppColors.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebase.streamCollection(
          widget.collectionName,
          whereField: 'projectId',
          whereValue: widget.projectId,
          // orderByField: 'date',  // Temporairement désactivé pour éviter l'erreur d'index
          // descending: true,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          if (documents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune donnée',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Appuyez sur + pour ajouter',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              final data = doc.data() as Map<String, dynamic>;
              
              return _buildListItem(context, doc.id, data);
            },
          );
        },
      ),
      floatingActionButton: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final canCreate = provider.canPerformAction('create');
          
          if (!canCreate) {
            return const SizedBox.shrink(); // Masquer le bouton si pas de permission
          }
          
          return FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => widget.formBuilder(widget.projectId),
                ),
              );
              if (result == true && mounted) {
                setState(() {});
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
            backgroundColor: AppColors.primary,
          );
        },
      ),
    );
  }

  Widget _buildListItem(BuildContext context, String documentId, Map<String, dynamic> data) {
    final date = data['date'] != null 
        ? DateTime.parse(data['date'])
        : data['dateOuverture'] != null
            ? DateTime.parse(data['dateOuverture'])
            : data['createdAt'] != null
                ? DateTime.parse(data['createdAt'])
                : DateTime.now();

    String title = '';
    String subtitle = '';
    Color? statusColor;

    // Personnalisation selon le type de collection
    switch (widget.collectionName) {
      case 'incidents':
        title = data['type'] ?? 'Incident';
        subtitle = data['personneAffectee'] ?? '';
        statusColor = _getGraviteColor(data['gravite']);
        break;
      case 'equipements':
        title = data['designation'] ?? 'Équipement';
        subtitle = '${data['quantiteFournie'] ?? 0}/${data['quantiteDemandee'] ?? 0}';
        statusColor = _getStatutColor(data['statut']);
        break;
      case 'dechets':
        title = data['typeDechet'] ?? 'Déchet';
        subtitle = '${data['quantite'] ?? 0} ${data['unite'] ?? ''}';
        break;
      case 'sensibilisations':
        title = data['theme'] ?? 'Sensibilisation';
        subtitle = '${data['nombreParticipants'] ?? 0} participants';
        break;
      case 'contentieux':
        title = data['objet'] ?? 'Contentieux';
        subtitle = data['nature'] ?? '';
        statusColor = _getStatutColor(data['statut']);
        break;
      case 'personnel':
        title = 'Relevé du ${date.day}/${date.month}/${date.year}';
        subtitle = 'Total: ${data['totalPersonnel'] ?? 0} personnes';
        break;
      case 'evenementChantier':
        title = data['composant'] ?? 'Événement';
        subtitle = data['activiteSource'] ?? '';
        break;
      case 'personnelV2':
        title = 'Relevé N°${data['numero'] ?? 0}';
        subtitle = 'Total: ${data['total'] ?? 0} personnes';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor ?? AppColors.primary,
          child: Icon(widget.icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(subtitle),
            ],
            const SizedBox(height: 4),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Consumer<AppProvider>(
          builder: (context, provider, child) {
            final canUpdate = provider.canPerformAction('update');
            final canDelete = provider.canPerformAction('delete');
            
            // Si aucune permission, ne pas afficher le menu
            if (!canUpdate && !canDelete) {
              return const SizedBox.shrink();
            }
            
            return PopupMenuButton(
              itemBuilder: (context) => [
                if (canUpdate)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                if (canDelete)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) async {
                if (value == 'edit' && canUpdate) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => widget.formBuilder(
                        widget.projectId,
                        documentId: documentId,
                        data: data,
                      ),
                    ),
                  );
                  if (result == true && mounted) {
                    setState(() {});
                  }
                } else if (value == 'delete' && canDelete) {
                  _confirmDelete(context, documentId, title);
                }
              },
            );
          },
        ),
        onTap: () async {
          final provider = Provider.of<AppProvider>(context, listen: false);
          final canUpdate = provider.canPerformAction('update');
          
          // Les visiteurs ne peuvent pas ouvrir le formulaire de modification
          if (!canUpdate) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vous n\'avez pas la permission de modifier'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => widget.formBuilder(
                widget.projectId,
                documentId: documentId,
                data: data,
              ),
            ),
          );
          if (result == true && mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  Color _getGraviteColor(String? gravite) {
    switch (gravite) {
      case 'leger':
        return Colors.green;
      case 'moyen':
        return Colors.orange;
      case 'grave':
        return Colors.red;
      case 'mortel':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  Color _getStatutColor(String? statut) {
    switch (statut) {
      case 'Demandé':
      case 'Ouvert':
        return Colors.orange;
      case 'En cours':
        return Colors.blue;
      case 'Fourni':
      case 'Résolu':
        return Colors.green;
      case 'Partiel':
        return Colors.amber;
      case 'Fermé':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _confirmDelete(BuildContext context, String documentId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "$title" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firebase.deleteDocument(widget.collectionName, documentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Supprimé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {});
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
  }
}
