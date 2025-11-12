import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import 'audit_form_screen.dart';

class AuditListScreen extends StatefulWidget {
  final String projectId;

  const AuditListScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<AuditListScreen> createState() => _AuditListScreenState();
}

class _AuditListScreenState extends State<AuditListScreen> {
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audits'),
        backgroundColor: AppColors.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('audit')
            .where('projectId', isEqualTo: widget.projectId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final projectAudits = snapshot.data ?? [];

          if (projectAudits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fact_check_rounded, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Aucun audit'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AuditFormScreen(
                            projectId: widget.projectId,
                          ),
                        ),
                      ).then((_) => setState(() {}));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvel Audit'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projectAudits.length,
            itemBuilder: (context, index) {
              final audit = projectAudits[index];
              final date = DateTime.parse(audit['date']);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    Icons.fact_check_rounded,
                    color: _getStatutColor(audit['statut']),
                  ),
                  title: Text(audit['titre'] ?? 'Sans titre'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${date.day}/${date.month}/${date.year}'),
                      Text('Responsable: ${audit['responsable'] ?? 'N/A'}'),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Modifier'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AuditFormScreen(
                                projectId: widget.projectId,
                                audit: audit,
                              ),
                            ),
                          ).then((_) => setState(() {}));
                        },
                      ),
                      PopupMenuItem(
                        child: const Text('Supprimer'),
                        onTap: () {
                          _showDeleteDialog(audit['id']);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AuditDetailScreen(
                          audit: audit,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuditFormScreen(
                projectId: widget.projectId,
              ),
            ),
          ).then((_) => setState(() {}));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(String auditId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'audit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              _db.delete('audits', auditId);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Audit supprimé')),
              );
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'interne':
        return Colors.blue;
      case 'externe':
        return Colors.orange;
      case 'supervision':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class AuditDetailScreen extends StatelessWidget {
  final Map<String, dynamic> audit;

  const AuditDetailScreen({
    super.key,
    required this.audit,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(audit['date']);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail Audit'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations Générales',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Date', '${date.day}/${date.month}/${date.year}'),
                    _buildDetailRow('Type d\'Audit', audit['statut']?.toString().toUpperCase() ?? 'N/A'),
                    _buildDetailRow('Titre', audit['titre'] ?? 'N/A'),
                    _buildDetailRow('Responsable', audit['responsable'] ?? 'N/A'),
                    if (audit['latitude'] != null && audit['longitude'] != null)
                      _buildDetailRow(
                        'Localisation',
                        '${audit['latitude']?.toStringAsFixed(6)}, ${audit['longitude']?.toStringAsFixed(6)}',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (audit['observations'] != null && audit['observations'].isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Observations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(audit['observations']),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (audit['photos'] != null && audit['photos'].isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Photos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (audit['photos'] as String)
                            .split(',')
                            .map((photo) => Image.asset(
                              photo,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
