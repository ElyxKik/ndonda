import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../../models/photo_report.dart';
import '../../utils/constants.dart';

/// Écran Rapport Photo - Bibliothèque de toutes les images liées au projet
class PhotoReportScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const PhotoReportScreen({
    Key? key,
    required this.projectId,
    required this.projectName,
  }) : super(key: key);

  @override
  State<PhotoReportScreen> createState() => _PhotoReportScreenState();
}

class _PhotoReportScreenState extends State<PhotoReportScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedModule = 'Tous';
  final List<String> _modules = [
    'Tous',
    'Incidents',
    'Équipements',
    'Déchets',
    'Sensibilisation',
    'Contentieux',
    'Personnel',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rapport Photo'),
            Text(
              widget.projectName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
            tooltip: 'Exporter le rapport',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _buildPhotoGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: AppColors.primary),
          const SizedBox(width: 12),
          const Text(
            'Filtrer par module:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _modules.map((module) {
                  final isSelected = _selectedModule == module;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(module),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedModule = module;
                        });
                      },
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      checkmarkColor: AppColors.primary,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return StreamBuilder<List<PhotoReportItem>>(
      stream: _getPhotosStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final photos = snapshot.data ?? [];

        if (photos.isEmpty) {
          return _buildEmptyState();
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            return _buildPhotoCard(photos[index]);
          },
        );
      },
    );
  }

  Widget _buildPhotoCard(PhotoReportItem photo) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () => _showPhotoDetail(photo),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                ),
                child: photo.imageUrl.isNotEmpty
                    ? Image.network(
                        photo.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                          );
                        },
                      )
                    : const Center(
                        child: Icon(Icons.image, size: 48, color: Colors.grey),
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getModuleColor(photo.module),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        photo.module,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        photo.legend,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune photo disponible',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedModule == 'Tous'
                ? 'Les photos des différents modules apparaîtront ici'
                : 'Aucune photo pour le module $_selectedModule',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<PhotoReportItem>> _getPhotosStream() {
    final collections = [
      'incidents',
      'equipements',
      'dechets',
      'sensibilisations',
      'contentieux',
      'personnel',
      'personnelV2',
      'evenementChantier',
    ];

    // Créer des streams pour chaque collection
    final streams = collections.map((collection) {
      return _firestore
          .collection(collection)
          .where('projectId', isEqualTo: widget.projectId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              // Vérifier si le document contient une photo
              return data['imageUrl'] != null && (data['imageUrl'] as String).isNotEmpty;
            })
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return PhotoReportItem(
                id: doc.id,
                projectId: widget.projectId,
                imageUrl: data['imageUrl'] ?? '',
                legend: data['description'] ?? data['titre'] ?? data['legend'] ?? '',
                module: _getModuleFromCollection(collection),
                moduleItemId: doc.id,
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                createdBy: data['createdBy'] ?? 'Utilisateur',
              );
            })
            .toList();
      });
    }).toList();

    // Combiner tous les streams
    return Rx.combineLatestList(streams).map((allPhotos) {
      // Aplatir la liste et filtrer par module sélectionné
      final flatPhotos = allPhotos.expand((photos) => photos).toList();
      
      if (_selectedModule != 'Tous') {
        return flatPhotos
            .where((photo) => photo.module == _selectedModule)
            .toList();
      }
      
      // Trier par date décroissante
      flatPhotos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return flatPhotos;
    });
  }

  String _getModuleFromCollection(String collection) {
    switch (collection) {
      case 'incidents':
        return 'Incidents';
      case 'equipements':
        return 'Équipements';
      case 'dechets':
        return 'Déchets';
      case 'sensibilisations':
        return 'Sensibilisation';
      case 'contentieux':
        return 'Contentieux';
      case 'personnel':
      case 'personnelV2':
        return 'Personnel';
      case 'evenementChantier':
        return 'Événement Chantier';
      default:
        return 'Autre';
    }
  }

  Color _getModuleColor(String module) {
    switch (module.toLowerCase()) {
      case 'incidents':
        return Colors.red;
      case 'équipements':
      case 'equipements':
        return Colors.blue;
      case 'déchets':
      case 'dechets':
        return Colors.green;
      case 'sensibilisation':
        return Colors.orange;
      case 'contentieux':
        return Colors.purple;
      case 'personnel':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _showPhotoDetail(PhotoReportItem photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppBar(
                title: Text(photo.module),
                backgroundColor: _getModuleColor(photo.module),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (photo.imageUrl.isNotEmpty)
                        Image.network(
                          photo.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Légende',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              photo.legend,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Ajoutée le ${_formatDate(photo.createdAt)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export du rapport photo en cours...'),
        backgroundColor: AppColors.primary,
      ),
    );
    // TODO: Implémenter l'export PDF
  }
}
