import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2E7D32); // Vert environnemental
  static const Color secondary = Color(0xFF1B5E20);
  static const Color accent = Color(0xFF66BB6A);
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);
}

class AppConstants {
  static const String appName = 'ENVIROX';
  static const String appSubtitle = 'Gestion Environnementale';
  
  // Report Types
  static const String reportWeekly = 'Hebdomadaire';
  static const String reportMonthly = 'Mensuel';
  static const String reportQuarterly = 'Trimestriel';
  static const String reportAnnual = 'Annuel';
  
  static const List<String> reportTypes = [
    reportWeekly,
    reportMonthly,
    reportQuarterly,
    reportAnnual,
  ];
  
  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleConsultant = 'consultant';
  static const String roleSupervision = 'supervision';
  static const String roleVisitor = 'visiteur';
  
  static const List<String> userRoles = [
    roleAdmin,
    roleConsultant,
    roleSupervision,
    roleVisitor,
  ];
  
  static const Map<String, String> roleLabels = {
    roleAdmin: 'Administrateur',
    roleConsultant: 'Consultant',
    roleSupervision: 'Supervision/Bailleur',
    roleVisitor: 'Visiteur',
  };
}

class ModuleInfo {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const ModuleInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class AppModules {
  static const List<ModuleInfo> modules = [
    ModuleInfo(
      id: 'project',
      title: 'Identification du projet',
      description: 'Informations de base du projet',
      icon: Icons.folder_outlined,
      color: Color(0xFF1976D2),
    ),
    ModuleInfo(
      id: 'evenements',
      title: 'Principaux événements',
      description: 'Événements survenus sur les chantiers',
      icon: Icons.event,
      color: Color(0xFFE64A19),
    ),
    ModuleInfo(
      id: 'pges',
      title: 'Mise en œuvre du PGES',
      description: 'Suivi des mesures de sauvegarde',
      icon: Icons.checklist,
      color: Color(0xFF388E3C),
    ),
    ModuleInfo(
      id: 'personnel',
      title: 'Personnel employé',
      description: 'Gestion des ressources humaines',
      icon: Icons.people,
      color: Color(0xFF7B1FA2),
    ),
    ModuleInfo(
      id: 'compensation',
      title: 'Compensation des actifs',
      description: 'Suivi des compensations',
      icon: Icons.account_balance_wallet,
      color: Color(0xFFF57C00),
    ),
    ModuleInfo(
      id: 'consultation',
      title: 'Consultation publique',
      description: 'Information et consultation du public',
      icon: Icons.forum,
      color: Color(0xFF0288D1),
    ),
    ModuleInfo(
      id: 'dechets',
      title: 'Gestion des déchets',
      description: 'Suivi de la gestion des déchets',
      icon: Icons.delete_outline,
      color: Color(0xFF5D4037),
    ),
    ModuleInfo(
      id: 'incidents',
      title: 'Incidents / Accidents',
      description: 'Maladies et accidents sur le chantier',
      icon: Icons.warning,
      color: Color(0xFFD32F2F),
    ),
    ModuleInfo(
      id: 'sensibilisation',
      title: 'Sensibilisation IST/VIH',
      description: 'Campagnes de sensibilisation',
      icon: Icons.health_and_safety,
      color: Color(0xFFC2185B),
    ),
    ModuleInfo(
      id: 'equipements',
      title: 'Équipements de protection',
      description: 'Gestion des EPI/EPC',
      icon: Icons.shield,
      color: Color(0xFF303F9F),
    ),
    ModuleInfo(
      id: 'contentieux',
      title: 'Traitement des contentieux',
      description: 'Suivi juridique',
      icon: Icons.gavel,
      color: Color(0xFF455A64),
    ),
    ModuleInfo(
      id: 'plaintes',
      title: 'Plaintes communautaires',
      description: 'Gestion des plaintes',
      icon: Icons.feedback,
      color: Color(0xFF00796B),
    ),
    ModuleInfo(
      id: 'cartographie',
      title: 'Cartographie interactive',
      description: 'Visualisation des sites et risques',
      icon: Icons.map,
      color: Color(0xFF689F38),
    ),
    ModuleInfo(
      id: 'esg',
      title: 'Indicateurs ESG',
      description: 'Environnement, Social, Gouvernance',
      icon: Icons.analytics,
      color: Color(0xFF512DA8),
    ),
  ];
}

// Status options
class StatusOptions {
  static const List<String> pgesStatut = [
    'Non commencé',
    'En cours',
    'Terminé',
    'Non conforme',
  ];

  static const List<String> compensationStatut = [
    'En attente',
    'Partielle',
    'Complète',
  ];

  static const List<String> equipementStatut = [
    'Demandé',
    'Partiel',
    'Complet',
  ];

  static const List<String> contentieuxStatut = [
    'Ouvert',
    'En cours',
    'Résolu',
    'En appel',
  ];

  static const List<String> plainteStatut = [
    'Enregistrée',
    'En traitement',
    'Résolue',
    'Rejetée',
  ];
}
