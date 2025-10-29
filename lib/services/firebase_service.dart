import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'notification_service.dart';

/// Service pour gérer les interactions avec Firebase
class FirebaseService {
  static final FirebaseService instance = FirebaseService._internal();
  factory FirebaseService() => instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();

  // ==================== Authentication ====================

  /// Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  /// Connexion anonyme
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  /// Connexion avec email et mot de passe
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Créer un compte avec email et mot de passe
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ==================== Firestore Operations ====================

  /// Ajouter un document à une collection
  Future<DocumentReference> addDocument(
    String collection,
    Map<String, dynamic> data, {
    String? notificationType,
    String? projectName,
  }) async {
    final docRef = await _firestore.collection(collection).add(data);
    
    // Notifications disabled - flutter_local_notifications removed
    
    return docRef;
  }

  /// Définir un document avec un ID spécifique
  Future<void> setDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    await _firestore
        .collection(collection)
        .doc(documentId)
        .set(data, SetOptions(merge: merge));
  }

  /// Mettre à jour un document
  Future<void> updateDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection(collection).doc(documentId).update(data);
  }

  /// Supprimer un document
  Future<void> deleteDocument(String collection, String documentId) async {
    await _firestore.collection(collection).doc(documentId).delete();
  }

  /// Obtenir un document
  Future<DocumentSnapshot> getDocument(
    String collection,
    String documentId,
  ) async {
    return await _firestore.collection(collection).doc(documentId).get();
  }

  /// Obtenir tous les documents d'une collection
  Future<QuerySnapshot> getCollection(String collection) async {
    return await _firestore.collection(collection).get();
  }

  /// Obtenir les documents avec une requête
  Future<QuerySnapshot> queryCollection(
    String collection, {
    String? whereField,
    dynamic whereValue,
    String? orderByField,
    bool descending = false,
    int? limit,
  }) async {
    Query query = _firestore.collection(collection);

    if (whereField != null && whereValue != null) {
      query = query.where(whereField, isEqualTo: whereValue);
    }

    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return await query.get();
  }

  /// Stream d'une collection
  Stream<QuerySnapshot> streamCollection(
    String collection, {
    String? whereField,
    dynamic whereValue,
    String? orderByField,
    bool descending = false,
  }) {
    Query query = _firestore.collection(collection);

    if (whereField != null && whereValue != null) {
      query = query.where(whereField, isEqualTo: whereValue);
    }

    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }

    return query.snapshots();
  }

  /// Stream d'un document
  Stream<DocumentSnapshot> streamDocument(
    String collection,
    String documentId,
  ) {
    return _firestore.collection(collection).doc(documentId).snapshots();
  }

  // ==================== Storage Operations ====================

  /// Uploader un fichier vers Firebase Storage
  Future<String> uploadFile(
    String filePath,
    String storagePath,
  ) async {
    final file = File(filePath);
    final ref = _storage.ref().child(storagePath);
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  /// Uploader plusieurs fichiers
  Future<List<String>> uploadFiles(
    List<String> filePaths,
    String storageFolder,
  ) async {
    final List<String> downloadUrls = [];

    for (int i = 0; i < filePaths.length; i++) {
      final fileName = filePaths[i].split('/').last;
      final storagePath = '$storageFolder/$fileName';
      final url = await uploadFile(filePaths[i], storagePath);
      downloadUrls.add(url);
    }

    return downloadUrls;
  }

  /// Supprimer un fichier de Firebase Storage
  Future<void> deleteFile(String storagePath) async {
    final ref = _storage.ref().child(storagePath);
    await ref.delete();
  }

  /// Obtenir l'URL de téléchargement d'un fichier
  Future<String> getDownloadUrl(String storagePath) async {
    final ref = _storage.ref().child(storagePath);
    return await ref.getDownloadURL();
  }

  // ==================== Batch Operations ====================

  /// Effectuer des opérations en batch
  Future<void> batchWrite(
    List<Map<String, dynamic>> operations,
  ) async {
    final batch = _firestore.batch();

    for (final operation in operations) {
      final type = operation['type'] as String;
      final collection = operation['collection'] as String;
      final documentId = operation['documentId'] as String?;
      final data = operation['data'] as Map<String, dynamic>?;

      final docRef = documentId != null
          ? _firestore.collection(collection).doc(documentId)
          : _firestore.collection(collection).doc();

      switch (type) {
        case 'set':
          batch.set(docRef, data!);
          break;
        case 'update':
          batch.update(docRef, data!);
          break;
        case 'delete':
          batch.delete(docRef);
          break;
      }
    }

    await batch.commit();
  }

  // ==================== Synchronization Helpers ====================

  /// Synchroniser les données locales vers Firebase
  Future<void> syncToFirebase(
    String collection,
    List<Map<String, dynamic>> localData,
  ) async {
    final batch = _firestore.batch();

    for (final item in localData) {
      final docRef = _firestore.collection(collection).doc(item['id']);
      batch.set(docRef, item, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Récupérer les données depuis Firebase
  Future<List<Map<String, dynamic>>> syncFromFirebase(
    String collection, {
    String? whereField,
    dynamic whereValue,
  }) async {
    final snapshot = await queryCollection(
      collection,
      whereField: whereField,
      whereValue: whereValue,
    );

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }
}
