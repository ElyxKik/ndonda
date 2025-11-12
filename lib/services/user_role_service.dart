import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_role.dart';

class UserRoleService {
  static final UserRoleService _instance = UserRoleService._internal();
  factory UserRoleService() => _instance;
  UserRoleService._internal();

  static UserRoleService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer le rôle d'un utilisateur
  Future<UserRole> getUserRole(String userId) async {
    try {
      print('📖 UserRoleService: Récupération du document users/$userId');
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        print('⚠️ UserRoleService: Document n\'existe pas, création avec rôle visiteur');
        // Si l'utilisateur n'existe pas, créer avec rôle visiteur par défaut
        await setUserRole(userId, UserRole.visiteur);
        return UserRole.visiteur;
      }

      final data = doc.data();
      print('📄 UserRoleService: Données du document: $data');
      final roleString = data?['role'] as String?;
      print('🔑 UserRoleService: Valeur du champ role: $roleString');
      
      if (roleString == null) {
        print('⚠️ UserRoleService: Champ role null, définition à visiteur');
        // Si pas de rôle défini, mettre visiteur par défaut
        await setUserRole(userId, UserRole.visiteur);
        return UserRole.visiteur;
      }

      final role = UserRole.fromString(roleString);
      print('✅ UserRoleService: Rôle converti: ${role.name}');
      return role;
    } catch (e) {
      print('❌ UserRoleService: Erreur lors de la récupération du rôle: $e');
      return UserRole.visiteur; // Par défaut en cas d'erreur
    }
  }

  // Définir le rôle d'un utilisateur
  Future<void> setUserRole(String userId, UserRole role) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'role': role.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Erreur lors de la définition du rôle: $e');
      rethrow;
    }
  }

  // Récupérer les permissions d'un utilisateur
  Future<UserPermissions> getUserPermissions(String userId) async {
    final role = await getUserRole(userId);
    return UserPermissions(role);
  }

  // Vérifier si l'utilisateur peut effectuer une action
  Future<bool> canPerformAction(String userId, String action) async {
    final permissions = await getUserPermissions(userId);
    
    switch (action) {
      case 'create':
        return permissions.canCreate;
      case 'update':
        return permissions.canUpdate;
      case 'delete':
        return permissions.canDelete;
      case 'viewReports':
        return permissions.canViewReports;
      case 'manageProjects':
        return permissions.canManageProjects;
      case 'manageUsers':
        return permissions.canManageUsers;
      default:
        return permissions.canRead;
    }
  }

  // Stream pour écouter les changements de rôle
  Stream<UserRole> watchUserRole(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return UserRole.visiteur;
      }
      final roleString = snapshot.data()?['role'] as String?;
      return roleString != null 
          ? UserRole.fromString(roleString) 
          : UserRole.visiteur;
    });
  }

  // Lister tous les utilisateurs avec leurs rôles (admin uniquement)
  Future<List<Map<String, dynamic>>> getAllUsersWithRoles() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': doc.id,
          'email': data['email'] ?? '',
          'displayName': data['displayName'] ?? 'Utilisateur',
          'role': UserRole.fromString(data['role'] ?? 'visiteur'),
          'createdAt': data['createdAt'],
        };
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs: $e');
      return [];
    }
  }
}
