import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project.dart';

/// Service de base de données utilisant Cloud Firestore
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DatabaseService._init();

  /// Obtenir l'ID de l'utilisateur actuel
  String? get currentUserId => _auth.currentUser?.uid;

  /// Vérifier si l'utilisateur est connecté
  bool get isUserSignedIn => _auth.currentUser != null;

  /// Connexion anonyme automatique si non connecté
  Future<void> ensureAuthenticated() async {
    if (!isUserSignedIn) {
      await _auth.signInAnonymously();
    }
  }

  // ==================== CRUD Operations for Projects ====================

  Future<void> createProject(Project project) async {
    await ensureAuthenticated();
    final projectData = project.toMap();
    projectData['userId'] = currentUserId;
    projectData['archived'] = false;
    
    await _firestore.collection('projects').doc(project.id).set(projectData);
  }

  Future<List<Project>> getAllProjects() async {
    await ensureAuthenticated();
    
    final snapshot = await _firestore
        .collection('projects')
        .where('archived', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Project.fromMap(doc.data())).toList();
  }

  Future<Project?> getProject(String id) async {
    await ensureAuthenticated();
    
    final doc = await _firestore.collection('projects').doc(id).get();
    
    if (doc.exists) {
      return Project.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> updateProject(Project project) async {
    await ensureAuthenticated();
    
    await _firestore.collection('projects').doc(project.id).update(project.toMap());
  }

  Future<void> deleteProject(String id) async {
    await ensureAuthenticated();
    
    // Soft delete - marquer comme archivé
    await _firestore.collection('projects').doc(id).update({'archived': true});
  }

  // ==================== Generic CRUD methods ====================

  Future<void> insert(String collection, Map<String, dynamic> data) async {
    await ensureAuthenticated();
    
    final id = data['id'] as String;
    data['createdBy'] = currentUserId;
    data['updatedAt'] = DateTime.now().toIso8601String();
    
    await _firestore.collection(collection).doc(id).set(data);
  }

  Future<List<Map<String, dynamic>>> query(
    String collection, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
  }) async {
    await ensureAuthenticated();
    
    Query query = _firestore.collection(collection);

    // Filtrer par projectId si spécifié dans where
    if (where != null && where.contains('projectId')) {
      final projectId = whereArgs?.first as String?;
      if (projectId != null) {
        query = query.where('projectId', isEqualTo: projectId);
      }
    }

    // Trier si spécifié
    if (orderBy != null) {
      final descending = orderBy.contains('DESC');
      final field = orderBy.replaceAll(' DESC', '').replaceAll(' ASC', '').trim();
      query = query.orderBy(field, descending: descending);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<void> update(
    String collection,
    Map<String, dynamic> data,
    String id,
  ) async {
    await ensureAuthenticated();
    
    data['updatedAt'] = DateTime.now().toIso8601String();
    await _firestore.collection(collection).doc(id).update(data);
  }

  Future<void> delete(String collection, String id) async {
    await ensureAuthenticated();
    
    await _firestore.collection(collection).doc(id).delete();
  }

  // ==================== Specific queries ====================

  Future<List<Map<String, dynamic>>> queryByDateRange(
    String collection,
    String projectId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    await ensureAuthenticated();
    
    final snapshot = await _firestore
        .collection(collection)
        .where('projectId', isEqualTo: projectId)
        .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Stream pour écouter les changements en temps réel
  Stream<List<Project>> streamProjects() {
    if (!isUserSignedIn) {
      return Stream.value([]);
    }

    return _firestore
        .collection('projects')
        .where('archived', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Project.fromMap(doc.data()))
            .toList());
  }

  /// Stream pour une collection spécifique
  Stream<List<Map<String, dynamic>>> streamCollection(
    String collection,
    String projectId,
  ) {
    if (!isUserSignedIn) {
      return Stream.value([]);
    }

    return _firestore
        .collection(collection)
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data())
            .toList());
  }

  Future<void> close() async {
    // Firestore ne nécessite pas de fermeture explicite
  }
}
