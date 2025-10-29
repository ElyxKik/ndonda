import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service d'authentification Firebase
class AuthService {
  static final AuthService instance = AuthService._init();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService._init();

  /// Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  /// Stream de l'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Vérifier si l'utilisateur est connecté
  bool get isSignedIn => _auth.currentUser != null;

  /// Obtenir l'ID de l'utilisateur actuel
  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== Connexion Anonyme ====================

  /// Connexion anonyme (par défaut)
  Future<UserCredential> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      
      // Créer un profil utilisateur basique
      await _createUserProfile(
        credential.user!.uid,
        displayName: 'Utilisateur Anonyme',
        email: null,
      );
      
      return credential;
    } catch (e) {
      throw Exception('Erreur de connexion anonyme: $e');
    }
  }

  // ==================== Email/Password ====================

  /// Inscription avec email et mot de passe
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    String? organization,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Mettre à jour le profil
      await credential.user!.updateDisplayName(displayName);

      // Créer le profil utilisateur dans Firestore
      await _createUserProfile(
        credential.user!.uid,
        displayName: displayName,
        email: email,
        organization: organization,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Connexion avec email et mot de passe
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Vérifier si le profil utilisateur existe, sinon le créer
      final userDoc = await _firestore.collection('users').doc(credential.user!.uid).get();
      
      if (!userDoc.exists) {
        print('⚠️ Profil utilisateur inexistant, création...');
        // Créer le profil s'il n'existe pas
        await _createUserProfile(
          credential.user!.uid,
          displayName: credential.user!.displayName ?? 'Utilisateur',
          email: credential.user!.email,
        );
      } else {
        // Mettre à jour la dernière connexion
        await _updateLastLogin(credential.user!.uid);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ==================== Gestion du profil ====================

  /// Créer un profil utilisateur dans Firestore
  Future<void> _createUserProfile(
    String userId, {
    required String displayName,
    String? email,
    String? organization,
  }) async {
    try {
      print('🔄 Création du profil utilisateur pour: $userId');
      print('📧 Email: $email, Nom: $displayName');
      
      final userDoc = _firestore.collection('users').doc(userId);
      
      // Vérifier si le profil existe déjà
      try {
        final docSnapshot = await userDoc.get();
        print('🔍 Vérification existence: ${docSnapshot.exists}');
        
        if (docSnapshot.exists && docSnapshot.data() != null) {
          final existingData = docSnapshot.data()!;
          print('📄 Données existantes: $existingData');
          
          // Vérifier si le profil est complet (contient les champs essentiels)
          final isComplete = existingData.containsKey('displayName') && 
                            existingData.containsKey('email') &&
                            existingData.containsKey('uid');
          
          if (isComplete) {
            print('ℹ️ Profil complet existe déjà, mise à jour lastLoginAt');
            // Si existe et est complet, mettre à jour uniquement lastLoginAt
            await userDoc.update({
              'lastLoginAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            print('✅ LastLoginAt mis à jour');
            return;
          } else {
            print('⚠️ Profil incomplet détecté, complétion des données manquantes...');
            // Le profil existe mais est incomplet, on va le compléter
          }
        }
      } catch (e) {
        print('⚠️ Erreur lors de la vérification (le document n\'existe probablement pas): $e');
      }

      print('📝 Création du nouveau profil utilisateur...');
      
      // Créer le nouveau profil utilisateur avec set (merge: true pour éviter les erreurs)
      final userData = {
        'uid': userId,
        'displayName': displayName,
        'email': email ?? '',
        'organization': organization ?? '',
        'role': 'visiteur', // Par défaut : visiteur (lecture seule)
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      };
      
      print('💾 Données à sauvegarder: $userData');
      
      await userDoc.set(userData, SetOptions(merge: true));
      
      print('✅ Profil utilisateur créé: $displayName ($email)');
      
      // Attendre un peu pour que Firestore propage les données
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Vérifier que le document a bien été créé
      final verifyDoc = await userDoc.get();
      if (verifyDoc.exists) {
        print('✅ Vérification: Document utilisateur existe dans Firestore');
        print('📄 Données créées: ${verifyDoc.data()}');
      } else {
        print('❌ ERREUR: Document utilisateur non créé dans Firestore');
        print('⚠️ Vérifiez les règles Firestore pour la collection "users"');
      }
    } catch (e) {
      print('❌ ERREUR lors de la création du profil: $e');
      print('🔍 Type d\'erreur: ${e.runtimeType}');
      // Relancer l'erreur pour que l'appelant puisse la gérer
      rethrow;
    }
  }

  /// Mettre à jour la dernière connexion
  Future<void> _updateLastLogin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('⚠️ Erreur mise à jour lastLoginAt: $e');
      // Ne pas bloquer la connexion si la mise à jour échoue
    }
  }

  /// Obtenir le profil utilisateur
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data();
  }

  /// Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ==================== Gestion des erreurs ====================

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Le mot de passe est trop faible';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'invalid-email':
        return 'Email invalide';
      case 'user-not-found':
        return 'Utilisateur non trouvé';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      default:
        return 'Erreur d\'authentification: ${e.message}';
    }
  }
}
