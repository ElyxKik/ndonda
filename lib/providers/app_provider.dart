import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project.dart';
import '../models/user_role.dart';
import '../services/database_service.dart';
import '../services/user_role_service.dart';

class AppProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final UserRoleService _roleService = UserRoleService.instance;
  
  Project? _currentProject;
  List<Project> _projects = [];
  bool _isLoading = false;
  String _selectedReportType = 'Mensuel';
  DateTime _selectedDate = DateTime.now();
  UserRole _userRole = UserRole.visiteur;
  UserPermissions? _userPermissions;

  Project? get currentProject => _currentProject;
  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  String get selectedReportType => _selectedReportType;
  DateTime get selectedDate => _selectedDate;
  UserRole get userRole => _userRole;
  UserPermissions? get userPermissions => _userPermissions;

  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      _projects = await _db.getAllProjects();
      if (_projects.isNotEmpty && _currentProject == null) {
        _currentProject = _projects.first;
      }
    } catch (e) {
      print('Error loading projects: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createProject(Project project) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _db.createProject(project);
      await loadProjects();
      _currentProject = project;
    } catch (e) {
      print('Error creating project: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProject(Project project) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _db.updateProject(project);
      await loadProjects();
      if (_currentProject?.id == project.id) {
        _currentProject = project;
      }
    } catch (e) {
      print('Error updating project: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProject(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _db.deleteProject(id);
      await loadProjects();
      if (_currentProject?.id == id) {
        _currentProject = _projects.isNotEmpty ? _projects.first : null;
      }
    } catch (e) {
      print('Error deleting project: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCurrentProject(Project project) {
    _currentProject = project;
    notifyListeners();
  }

  void clearCurrentProject() {
    _currentProject = null;
    notifyListeners();
  }

  void setReportType(String reportType) {
    _selectedReportType = reportType;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // Charger le rôle de l'utilisateur
  Future<void> loadUserRole(String userId) async {
    try {
      print('🔍 Chargement du rôle pour userId: $userId');
      
      // Vérifier si l'utilisateur est admin via UserRoleService
      final role = await _roleService.getUserRole(userId);
      
      print('✅ Rôle récupéré: ${role.name} (${role.displayName})');
      
      _userRole = role;
      _userPermissions = UserPermissions(role);
      notifyListeners();
    } catch (e) {
      print('❌ Erreur lors du chargement du rôle: $e');
      _userRole = UserRole.consultant;
      _userPermissions = UserPermissions(UserRole.consultant);
      notifyListeners();
    }
  }
  
  // Vérifier si l'utilisateur est admin
  bool get isAdmin => _userRole == UserRole.admin;

  // Vérifier si l'utilisateur peut effectuer une action
  bool canPerformAction(String action) {
    // Lecture: tous les utilisateurs authentifiés
    if (action == 'read' || action == 'viewReports') {
      return true;
    }
    
    // Création: uniquement les admins
    if (action == 'create') {
      return _userRole == UserRole.admin;
    }
    
    // Modification et suppression: uniquement les admins
    if (action == 'update' || action == 'delete') {
      return _userRole == UserRole.admin;
    }
    
    // Gestion des utilisateurs: uniquement pour les admins
    if (action == 'manageUsers') {
      return _userRole == UserRole.admin;
    }
    
    // Gestion des projets
    if (action == 'manageProjects') {
      return _userRole == UserRole.admin;
    }
    
    return false;
  }
  
  // Vérifier si l'utilisateur est le créateur d'un document
  bool isCreator(String? createdBy, String currentUserId) {
    return createdBy == currentUserId;
  }
}
