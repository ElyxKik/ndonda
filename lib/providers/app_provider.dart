import 'package:flutter/foundation.dart';
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
      _userRole = await _roleService.getUserRole(userId);
      _userPermissions = UserPermissions(_userRole);
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement du rôle: $e');
      _userRole = UserRole.visiteur;
      _userPermissions = UserPermissions(UserRole.visiteur);
      notifyListeners();
    }
  }

  // Vérifier si l'utilisateur peut effectuer une action
  bool canPerformAction(String action) {
    if (_userPermissions == null) return false;
    
    switch (action) {
      case 'create':
        return _userPermissions!.canCreate;
      case 'update':
        return _userPermissions!.canUpdate;
      case 'delete':
        return _userPermissions!.canDelete;
      case 'viewReports':
        return _userPermissions!.canViewReports;
      case 'manageProjects':
        return _userPermissions!.canManageProjects;
      case 'manageUsers':
        return _userPermissions!.canManageUsers;
      default:
        return _userPermissions!.canRead;
    }
  }
}
