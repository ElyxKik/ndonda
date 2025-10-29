enum UserRole {
  admin,
  consultant,
  supervision,
  visiteur;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.consultant:
        return 'Consultant';
      case UserRole.supervision:
        return 'Supervision/Bailleur';
      case UserRole.visiteur:
        return 'Visiteur';
    }
  }

  String get description {
    switch (this) {
      case UserRole.admin:
        return 'Gestion complète de l\'application, création des comptes, paramétrage des modules';
      case UserRole.consultant:
        return 'Analyse des données, rédaction de rapports, recommandations techniques';
      case UserRole.supervision:
        return 'Tableau de bord (lecture seule), validation des rapports par commentaire';
      case UserRole.visiteur:
        return 'Accès limité à la visualisation des données, sans modification ni saisie';
    }
  }

  // Convertir depuis une string
  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'administrateur':
        return UserRole.admin;
      case 'consultant':
        return UserRole.consultant;
      case 'supervision':
      case 'bailleur':
        return UserRole.supervision;
      case 'visiteur':
      case 'visitor':
        return UserRole.visiteur;
      default:
        return UserRole.visiteur; // Par défaut
    }
  }

  // Convertir vers une string pour Firestore
  String toFirestore() {
    return name;
  }
}

class UserPermissions {
  final UserRole role;

  UserPermissions(this.role);

  // Permissions de lecture
  bool get canRead => true; // Tous peuvent lire

  // Permissions d'ajout
  bool get canCreate {
    return role == UserRole.admin || role == UserRole.consultant;
  }

  // Permissions de modification
  bool get canUpdate {
    return role == UserRole.admin || role == UserRole.consultant;
  }

  // Permissions de suppression
  bool get canDelete {
    return role == UserRole.admin;
  }

  // Accès aux rapports
  bool get canViewReports {
    return role == UserRole.admin || role == UserRole.consultant;
  }

  // Gestion des projets
  bool get canManageProjects {
    return role == UserRole.admin;
  }

  // Gestion des utilisateurs
  bool get canManageUsers {
    return role == UserRole.admin;
  }
  
  // Accès au rapport photo
  bool get canAccessPhotoReport {
    return role == UserRole.admin || role == UserRole.supervision;
  }
  
  // Accès au rapport d'activité
  bool get canAccessActivityReport {
    return role == UserRole.admin || role == UserRole.consultant;
  }
  
  // Accès au rapport de supervision
  bool get canAccessSupervisionReport {
    return role == UserRole.admin || role == UserRole.supervision;
  }
  
  // Accès au rapport de consultant
  bool get canAccessConsultantReport {
    return role == UserRole.admin || role == UserRole.consultant;
  }
  
  // Peut ajouter des commentaires/validations
  bool get canComment {
    return role == UserRole.admin || role == UserRole.supervision;
  }
}
