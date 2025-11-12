import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
            return const SizedBox.shrink();
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
    DateTime date = DateTime.now();
    
    // Fonction helper pour convertir Timestamp ou String en DateTime
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      // Gérer les Timestamps Firestore
      if (value.runtimeType.toString().contains('Timestamp')) {
        try {
          return (value as dynamic).toDate();
        } catch (e) {
          return null;
        }
      }
      return null;
    }
    
    // Essayer de récupérer la date dans cet ordre
    date = _parseDate(data['date']) 
        ?? _parseDate(data['dateOuverture'])
        ?? _parseDate(data['createdAt'])
        ?? DateTime.now();

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
      case 'mise_en_oeuvre_pges':
        title = data['actionPrise'] ?? 'Action PGES';
        subtitle = 'Réalisé: ${data['realise'] ?? 'Non'}';
        statusColor = data['realise'] == 'Oui' ? Colors.green : Colors.orange;
        break;
      case 'audit':
        final statut = data['statut'] ?? 'N/A';
        final mois = data['mois'] ?? '';
        final zone = data['zone'] ?? '';
        title = 'Audit ${statut.toUpperCase()}';
        subtitle = mois.isNotEmpty ? '$mois${zone.isNotEmpty ? ' - $zone' : ''}' : zone;
        statusColor = _getAuditStatutColor(statut);
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
            // Vérifier si l'utilisateur est admin
            final provider = Provider.of<AppProvider>(context, listen: false);
            final canModify = provider.canPerformAction('update');
            
            return PopupMenuButton(
              itemBuilder: (context) => [
                // Bouton Voir pour tous les utilisateurs
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 20),
                      SizedBox(width: 8),
                      Text('Voir'),
                    ],
                  ),
                ),
                // Boutons Modifier et Supprimer uniquement pour les admins
                if (canModify)
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
                if (canModify)
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
                if (value == 'view') {
                  // Afficher les détails du document
                  _showDocumentDetails(context, documentId, data, title);
                } else if (value == 'edit' && canModify) {
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
                } else if (value == 'delete' && canModify) {
                  _confirmDelete(context, documentId, title);
                }
              },
            );
          },
        ),
        onTap: () async {
          final provider = Provider.of<AppProvider>(context, listen: false);
          final canModify = provider.canPerformAction('update');
          
          // Si l'utilisateur n'est pas admin, afficher seulement les détails
          if (!canModify) {
            _showDocumentDetails(context, documentId, data, title);
            return;
          }
          
          // Si c'est un admin, ouvrir le formulaire de modification
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

  void _showDocumentDetails(BuildContext context, String documentId, Map<String, dynamic> data, String title) {
    // Cas spécial pour la collection "audit"
    if (widget.collectionName == 'audit') {
      _showAuditDetails(context, data);
      return;
    }

    // Cas spécial pour la collection "mise_en_oeuvre_pges"
    if (widget.collectionName == 'mise_en_oeuvre_pges') {
      _showPgesDetails(context, data);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...data.entries.map((entry) {
                final key = entry.key;
                final value = entry.value;
                
                // Ignorer les champs non affichables
                if (key == 'photos' || key == 'projectId' || key == 'createdBy') {
                  return const SizedBox.shrink();
                }
                
                String displayValue = '';
                if (value is List) {
                  displayValue = value.join(', ');
                } else if (value is Map) {
                  displayValue = value.toString();
                } else {
                  displayValue = value.toString();
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        key,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayValue,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showAuditDetails(BuildContext context, Map<String, dynamic> data) {
    final statut = data['statut'] ?? 'N/A';
    final responsable = data['responsableHSE'] ?? 'N/A';
    final mois = data['mois'] ?? 'N/A';
    final zone = data['zone'] ?? 'N/A';
    final observations = data['observations'] ?? '';
    
    final envIndicators = data['environmentalIndicators'] as Map<String, dynamic>? ?? {};
    final socialIndicators = data['socialIndicators'] as Map<String, dynamic>? ?? {};
    final quantIndicators = data['quantitativeIndicators'] as Map<String, dynamic>? ?? {};
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails de l\'Audit'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Informations générales
              _buildDetailSection('Informations Générales', [
                _buildDetailRow('Responsable HSE', responsable),
                _buildDetailRow('Mois', mois),
                _buildDetailRow('Zone', zone),
                _buildDetailRow('Statut', statut.toUpperCase(), 
                  color: _getAuditStatutColor(statut)),
              ]),
              
              const SizedBox(height: 16),
              
              // Indicateurs environnementaux
              if (envIndicators.isNotEmpty) ...[
                _buildDetailSection('Indicateurs Environnementaux', 
                  envIndicators.entries.map((e) => 
                    _buildDetailRow(e.key, e.value.toString())).toList()),
                const SizedBox(height: 16),
              ],
              
              // Indicateurs sociaux
              if (socialIndicators.isNotEmpty) ...[
                _buildDetailSection('Indicateurs Sociaux', 
                  socialIndicators.entries.map((e) => 
                    _buildDetailRow(e.key, e.value.toString())).toList()),
                const SizedBox(height: 16),
              ],
              
              // Indicateurs quantitatifs
              if (quantIndicators.isNotEmpty) ...[
                _buildDetailSection('Indicateurs Quantitatifs', 
                  quantIndicators.entries.map((e) => 
                    _buildDetailRow(e.key, e.value.toString())).toList()),
                const SizedBox(height: 16),
              ],
              
              // Observations
              if (observations.isNotEmpty) ...[
                const Text(
                  'Observations',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(observations, style: const TextStyle(fontSize: 13)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAuditStatutColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'interne':
        return Colors.blue;
      case 'externe':
        return Colors.purple;
      case 'supervision':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showPgesDetails(BuildContext context, Map<String, dynamic> data) {
    final indicators = data['indicators'] as List? ?? [];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails Mise en oeuvre PGES'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Informations générales
              if (data['createdAt'] != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date de création',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(data['createdAt']),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Indicateurs
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Indicateurs PGES',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              
              if (indicators.isEmpty)
                const Text('Aucun indicateur')
              else
                ...indicators.map((indicator) {
                  final name = indicator['name'] ?? '';
                  final realise = indicator['realise'] ?? 'Non';
                  final actionPrise = indicator['actionPrise'] ?? '';
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text(
                                'Réalisé: ',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: realise == 'Oui' ? Colors.green[100] : Colors.orange[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  realise,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: realise == 'Oui' ? Colors.green[700] : Colors.orange[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (actionPrise.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Action prise:',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              actionPrise,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime date;
      if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else if (timestamp.runtimeType.toString().contains('Timestamp')) {
        date = (timestamp as dynamic).toDate();
      } else {
        return 'N/A';
      }
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }
}
