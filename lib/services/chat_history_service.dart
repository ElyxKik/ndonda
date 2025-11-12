import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Représente un message dans l'historique
class ChatMessage {
  final String id;
  final String role; // 'user' ou 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  /// Convertir en JSON pour la sauvegarde
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Créer depuis JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Service pour gérer l'historique des conversations
class ChatHistoryService {
  static const String _storageKey = 'firebase_ai_chat_history';

  late SharedPreferences _prefs;
  List<ChatMessage> _messages = [];
  bool _initialized = false;

  /// Initialiser le service
  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    await _loadHistory();
    _initialized = true;
  }

  /// Charger l'historique depuis le stockage local
  Future<void> _loadHistory() async {
    try {
      final jsonString = _prefs.getString(_storageKey);
      if (jsonString == null) {
        _messages = [];
        return;
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      _messages = jsonList
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList();

      print('✅ Historique chargé: ${_messages.length} messages');
    } catch (e) {
      print('❌ Erreur lors du chargement de l\'historique: $e');
      _messages = [];
    }
  }

  /// Sauvegarder l'historique dans le stockage local
  Future<void> _saveHistory() async {
    try {
      final jsonList = _messages.map((msg) => msg.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _prefs.setString(_storageKey, jsonString);
      print('✅ Historique sauvegardé: ${_messages.length} messages');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde de l\'historique: $e');
    }
  }

  /// Ajouter un message utilisateur
  Future<void> addUserMessage(String content) async {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    );
    _messages.add(message);
    await _saveHistory();
  }

  /// Ajouter un message assistant
  Future<void> addAssistantMessage(String content) async {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'assistant',
      content: content,
      timestamp: DateTime.now(),
    );
    _messages.add(message);
    await _saveHistory();
  }

  /// Obtenir tous les messages
  List<ChatMessage> getMessages() {
    return List.from(_messages);
  }

  /// Obtenir les N derniers messages
  List<ChatMessage> getLastMessages(int count) {
    if (_messages.length <= count) {
      return List.from(_messages);
    }
    return _messages.sublist(_messages.length - count);
  }

  /// Obtenir le contexte de conversation (pour Gemini)
  String getConversationContext(int maxMessages) {
    final lastMessages = getLastMessages(maxMessages);
    if (lastMessages.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('Historique de la conversation:');
    buffer.writeln('---');

    for (final msg in lastMessages) {
      final role = msg.role == 'user' ? 'Utilisateur' : 'Assistant';
      buffer.writeln('$role: ${msg.content}');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Effacer tout l'historique
  Future<void> clearHistory() async {
    _messages.clear();
    await _prefs.remove(_storageKey);
    print('✅ Historique effacé');
  }

  /// Obtenir le nombre de messages
  int getMessageCount() {
    return _messages.length;
  }

  /// Exporter l'historique en JSON
  String exportAsJson() {
    final jsonList = _messages.map((msg) => msg.toJson()).toList();
    return jsonEncode(jsonList);
  }

  /// Exporter l'historique en texte lisible
  String exportAsText() {
    final buffer = StringBuffer();
    buffer.writeln('=== Historique des Conversations ===');
    buffer.writeln('Date: ${DateTime.now()}');
    buffer.writeln('Total de messages: ${_messages.length}');
    buffer.writeln('');

    for (final msg in _messages) {
      final role = msg.role == 'user' ? '👤 Utilisateur' : '🤖 Assistant';
      final time = msg.timestamp.toString().split('.')[0];
      buffer.writeln('[$time] $role:');
      buffer.writeln(msg.content);
      buffer.writeln('---');
    }

    return buffer.toString();
  }
}
