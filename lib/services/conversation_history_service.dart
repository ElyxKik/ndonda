import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

/// Représente un message dans une conversation
class ConversationMessage {
  final String id;
  final String role; // 'user' ou 'assistant'
  final String content;
  final DateTime timestamp;

  ConversationMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp,
    };
  }

  factory ConversationMessage.fromMap(Map<String, dynamic> map) {
    return ConversationMessage(
      id: map['id'] as String,
      role: map['role'] as String,
      content: map['content'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}

/// Représente une conversation complète
class Conversation {
  final String id;
  final String userId;
  final String type; // 'simple' ou 'firebase'
  final String title;
  final List<ConversationMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'messages': messages.map((m) => m.toMap()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'messageCount': messages.length,
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    final messagesList = (map['messages'] as List<dynamic>?)
            ?.map((m) => ConversationMessage.fromMap(m as Map<String, dynamic>))
            .toList() ??
        [];

    return Conversation(
      id: map['id'] as String,
      userId: map['userId'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      messages: messagesList,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }
}

/// Service pour gérer l'historique des conversations dans Firestore
class ConversationHistoryService {
  static const String _collectionName = 'ai_conversations';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Créer une nouvelle conversation
  Future<String> createConversation({
    required String type, // 'simple' ou 'firebase'
    required String title,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Utilisateur non authentifié');

      final conversationId = const Uuid().v4();
      final now = DateTime.now();

      await _firestore
          .collection(_collectionName)
          .doc(conversationId)
          .set({
        'id': conversationId,
        'userId': userId,
        'type': type,
        'title': title,
        'messages': [],
        'createdAt': now,
        'updatedAt': now,
        'messageCount': 0,
      });

      return conversationId;
    } catch (e) {
      print('❌ Erreur création conversation: $e');
      rethrow;
    }
  }

  /// Ajouter un message à une conversation
  Future<void> addMessage({
    required String conversationId,
    required String role,
    required String content,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Utilisateur non authentifié');

      final message = ConversationMessage(
        id: const Uuid().v4(),
        role: role,
        content: content,
        timestamp: DateTime.now(),
      );

      await _firestore.collection(_collectionName).doc(conversationId).update({
        'messages': FieldValue.arrayUnion([message.toMap()]),
        'updatedAt': DateTime.now(),
        'messageCount': FieldValue.increment(1),
      });

      print('✅ Message ajouté à la conversation');
    } catch (e) {
      print('❌ Erreur ajout message: $e');
      rethrow;
    }
  }

  /// Obtenir toutes les conversations de l'utilisateur
  Future<List<Conversation>> getUserConversations({
    required String type, // 'simple', 'firebase', ou '' pour tous
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Utilisateur non authentifié');

      // Requête de base: userId + tri par updatedAt
      Query query = _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true);

      final snapshot = await query.get();

      var conversations = snapshot.docs
          .map((doc) => Conversation.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Filtrer par type en mémoire si nécessaire
      if (type.isNotEmpty) {
        conversations = conversations.where((c) => c.type == type).toList();
      }

      return conversations;
    } catch (e) {
      print('❌ Erreur récupération conversations: $e');
      return [];
    }
  }

  /// Obtenir une conversation spécifique
  Future<Conversation?> getConversation(String conversationId) async {
    try {
      final doc =
          await _firestore.collection(_collectionName).doc(conversationId).get();

      if (!doc.exists) return null;

      return Conversation.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('❌ Erreur récupération conversation: $e');
      return null;
    }
  }

  /// Supprimer une conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(conversationId)
          .delete();
      print('✅ Conversation supprimée');
    } catch (e) {
      print('❌ Erreur suppression conversation: $e');
      rethrow;
    }
  }

  /// Mettre à jour le titre d'une conversation
  Future<void> updateConversationTitle(
    String conversationId,
    String newTitle,
  ) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(conversationId)
          .update({
        'title': newTitle,
        'updatedAt': DateTime.now(),
      });
      print('✅ Titre mis à jour');
    } catch (e) {
      print('❌ Erreur mise à jour titre: $e');
      rethrow;
    }
  }

  /// Générer un titre automatique basé sur le premier message
  String generateTitle(String firstMessage) {
    if (firstMessage.isEmpty) return 'Nouvelle conversation';
    if (firstMessage.length > 50) {
      return firstMessage.substring(0, 50) + '...';
    }
    return firstMessage;
  }
}
