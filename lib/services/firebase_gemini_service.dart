import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:math';
import '../config/gemini_config.dart';
import 'chat_history_service.dart';

/// Service pour intégrer Firebase et Gemini avec recherche intelligente
/// Utilise l'algorithme de Levenshtein pour trouver les documents pertinents
class FirebaseGeminiService {
  late GenerativeModel _model;
  late ChatSession _chatSession;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late ChatHistoryService _historyService;
  
  // Collections à rechercher (toutes les collections existantes)
  static const List<String> collections = [
    'projects',
    'incidents',
    'equipements',
    'dechets',
    'sensibilisations',
    'contentieux',
    'personnel',
    'personnelV2',
    'evenementChantier',
    'photo_reports',
    'activityReports',
    'supervisionReports',
    'consultantReports',
    'hseIndicators',
    'mise_en_oeuvre_pges',
    'audit',
  ];

  FirebaseGeminiService() {
    if (!GeminiConfig.isConfigured()) {
      throw Exception(
        'Clé API Gemini non configurée. '
        'Veuillez configurer votre clé API dans lib/config/gemini_config.dart'
      );
    }

    _historyService = ChatHistoryService();
    
    _model = GenerativeModel(
      model: GeminiConfig.model,
      apiKey: GeminiConfig.apiKey,
      systemInstruction: Content.text(
        'Tu es un assistant intelligent et chaleureux qui aide les utilisateurs '
        'à trouver des informations dans une base de données Firestore. '
        'Réponds toujours en français, de manière naturelle et conversationnelle. '
        'Ne fais jamais d\'inventions ou d\'hallucinations. '
        'Utilise uniquement les informations fournies.'
      ),
    );
    _chatSession = _model.startChat();
  }

  /// Initialiser le service (charger l'historique)
  Future<void> initialize() async {
    await _historyService.initialize();
  }

  /// Filtre les données sensibles avant de les envoyer à Gemini
  Map<String, dynamic> _filterSensitiveData(Map<String, dynamic> data) {
    final sensitiveFields = [
      'password',
      'apiKey',
      'token',
      'secret',
      'fcmToken',
      'refreshToken',
    ];

    final filtered = Map<String, dynamic>.from(data);

    sensitiveFields.forEach((field) {
      filtered.remove(field);
    });

    // Limiter la taille des données
    if (filtered.containsKey('description') &&
        filtered['description'] is String) {
      String desc = filtered['description'];
      if (desc.length > 500) {
        filtered['description'] = desc.substring(0, 500) + '...';
      }
    }

    return filtered;
  }

  /// Normalise le texte: minuscule + suppression accents
  String _normalize(String text) {
    if (text.isEmpty) return '';
    
    // Minuscule
    String normalized = text.toLowerCase();
    
    // Remplacer accents
    final accents = {
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'à': 'a', 'â': 'a', 'ä': 'a',
      'î': 'i', 'ï': 'i',
      'ô': 'o', 'ö': 'o',
      'ù': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c',
      'œ': 'oe',
      'æ': 'ae',
    };
    
    accents.forEach((accent, replacement) {
      normalized = normalized.replaceAll(accent, replacement);
    });
    
    return normalized;
  }

  /// Calcule la distance de Levenshtein entre deux chaînes
  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> previousRow = List<int>.generate(b.length + 1, (i) => i);
    List<int> currentRow = List<int>.filled(b.length + 1, 0);

    for (int i = 0; i < a.length; i++) {
      currentRow[0] = i + 1;
      for (int j = 0; j < b.length; j++) {
        int insert = currentRow[j] + 1;
        int delete = previousRow[j + 1] + 1;
        int replace = previousRow[j] + (a[i] == b[j] ? 0 : 1);
        currentRow[j + 1] = min(insert, min(delete, replace));
      }
      var temp = previousRow;
      previousRow = currentRow;
      currentRow = temp;
    }
    return previousRow[b.length];
  }

  /// Calcule un score de similarité entre la requête et un document
  double _similarityScore(String query, Map<String, dynamic> doc, String collectionName) {
    final q = _normalize(query);
    double score = 0.0;

    // Extraire les mots-clés de la requête (ignorer les mots vides)
    final stopWords = {'le', 'la', 'les', 'de', 'du', 'des', 'un', 'une', 'et', 'ou', 'est', 'sont', 'a', 'au', 'pour', 'par', 'avec', 'sur', 'dans', 'en', 'me', 'moi', 'te', 'toi', 'nous', 'vous', 'lui', 'ce', 'cet', 'cette', 'ces', 'mon', 'ton', 'son', 'notre', 'votre', 'qui', 'que', 'quoi', 'quel', 'quelle', 'quels', 'quelles', 'parle', 'donne', 'dis', 'pas', 'fais', 'fait'};
    final keywords = q
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2 && !stopWords.contains(word))
        .toList();

    if (keywords.isEmpty) return 0.0;

    // Champs prioritaires avec leurs poids
    final priorityFields = {
      'nom': 1.0,
      'localisation': 0.9,
      'maitre_oeuvre': 0.8,
      'maitre_ouvrage': 0.8,
      'titre': 0.8,
      'type': 0.7,
      'entreprises': 0.7,
      'description': 0.6,
      'statut': 0.5,
    };

    // Chercher dans les champs prioritaires
    for (final entry in priorityFields.entries) {
      final field = entry.key;
      final weight = entry.value;
      final value = _normalize((doc[field] ?? '').toString());
      if (value.isEmpty) continue;
      
      for (final keyword in keywords) {
        if (value.contains(keyword)) {
          score += 1.5 * weight; // Match exact: +1.5
        } else {
          int lev = _levenshtein(keyword, value);
          double s = max(0.0, 1.0 - lev / max(keyword.length, value.length));
          score += s * weight; // Levenshtein
        }
      }
    }

    // Chercher dans TOUS les autres champs aussi
    for (final entry in doc.entries) {
      final field = entry.key;
      final value = _normalize(entry.value.toString());
      
      // Ignorer les champs déjà traités et les champs sensibles
      if (priorityFields.containsKey(field) || field.startsWith('_') || value.isEmpty) {
        continue;
      }
      
      for (final keyword in keywords) {
        if (value.contains(keyword)) {
          score += 0.5; // Poids réduit pour les autres champs
        } else {
          int lev = _levenshtein(keyword, value);
          double s = max(0.0, 1.0 - lev / max(keyword.length, value.length));
          if (s > 0.6) {
            score += s * 0.3; // Bonus pour correspondances partielles
          }
        }
      }
    }

    // Bonus pour la collection
    final col = _normalize(collectionName);
    for (final keyword in keywords) {
      if (col.contains(keyword)) {
        score += 3.0;
      } else {
        int levCol = _levenshtein(keyword, col);
        score += max(0.0, 1.0 - levCol / max(keyword.length, col.length)) * 2.0;
      }
    }

    // Normaliser le score (très généreux)
    return score / keywords.length;
  }

  /// Recherche intelligente dans plusieurs collections
  Future<List<Map<String, dynamic>>> _searchFirestore(String query) async {
    try {
      List<Map<String, dynamic>> allResults = [];
      print('🔍 Recherche pour: "$query"');

      // Rechercher dans toutes les collections
      for (final collection in collections) {
        try {
          final snapshot = await _firestore
              .collection(collection)
              .limit(100)
              .get();

          print('📊 Collection "$collection": ${snapshot.docs.length} documents');

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final score = _similarityScore(query, data, collection);

            print('  - ${data['nom'] ?? 'Sans nom'}: score=$score');

            // Garder seulement les résultats pertinents (seuil très réduit)
            if (score > 0.0) {
              allResults.add({
                'id': doc.id,
                'collection': collection,
                'score': score,
                ..._filterSensitiveData(data),
              });
            }
          }
        } catch (e) {
          print('❌ Erreur lors de la recherche dans $collection: $e');
        }
      }

      // Trier par score décroissant
      allResults.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

      // Garder les 5 plus pertinents
      final results = allResults.take(5).toList();
      print('✅ Résultats trouvés: ${results.length} documents');

      return results;
    } catch (e) {
      print('❌ Erreur lors de la recherche Firestore: $e');
      return [];
    }
  }

  /// Formate une valeur pour l'affichage
  String _formatValue(dynamic v) {
    if (v == null) return '';
    if (v is Timestamp) {
      try {
        return v.toDate().toString().split('.')[0];
      } catch (_) {
        return v.toString();
      }
    }
    if (v is DateTime) return v.toString().split('.')[0];
    if (v is num || v is bool) return v.toString();
    if (v is List) {
      if (v.isEmpty) return '';
      return v.take(10).map((e) => e.toString()).join(', ');
    }
    if (v is Map) {
      final entries = v.entries.take(10).map((e) => '${e.key}: ${e.value}').join(', ');
      return entries;
    }
    final s = v.toString().trim();
    return s.length > 300 ? s.substring(0, 300) + '…' : s;
  }

  /// Construit le contexte Firebase pour le prompt (avec recherche intelligente)
  Future<String> _buildFirebaseContextWithSearch(String question) async {
    // Rechercher les documents pertinents selon la question
    final results = await _searchFirestore(question);

    print('Résultats de recherche: ${results.length} documents');

    // Formatter les résultats en incluant TOUS les champs disponibles
    String contexte = '';
    if (results.isNotEmpty) {
      final buffer = StringBuffer();
      
      for (final doc in results) {
        final collection = (doc['collection'] ?? 'Données').toString();
        final score = (doc['score'] is num)
            ? (doc['score'] as num).toDouble().toStringAsFixed(2)
            : '0.00';

        // Déterminer le titre (alias)
        final title = (doc['nom'] ?? doc['titre'] ?? doc['name'] ?? doc['code'] ?? 'Nom inconnu').toString();

        buffer.writeln('[$collection] (Score: $score)');
        buffer.writeln('Titre: $title');

        // Clés à ignorer
        const ignoredKeys = {'collection', 'score', 'id', 'password', 'apiKey', 'token', 'secret', 'fcmToken', 'refreshToken'};
        const primaryShown = {'nom', 'titre', 'name', 'code'};

        // Alias pour meilleur affichage
        final aliases = <String, List<String>>{
          'Localisation': ['localisation', 'lieu', 'site', 'zone'],
          'Maître d\'ouvrage': ['maitre_ouvrage', 'moa', 'maitreOuvrage'],
          'Maître d\'œuvre': ['maitre_oeuvre', 'moe', 'maitreOeuvre'],
          'Montant': ['montant', 'budget', 'cout', 'coût'],
          'Durée': ['delai', 'duree', 'durée', 'duration'],
          'Statut': ['statut', 'status'],
          'Type': ['type', 'categorie', 'category'],
        };

        // Afficher les alias connus s'ils existent
        for (final entry in aliases.entries) {
          final label = entry.key;
          final keys = entry.value;
          dynamic value;
          for (final k in keys) {
            if (doc.containsKey(k) && doc[k] != null && doc[k].toString().trim().isNotEmpty) {
              value = doc[k];
              break;
            }
          }
          if (value != null) {
            final fv = _formatValue(value);
            if (fv.isNotEmpty) buffer.writeln('$label: $fv');
          }
        }

        // Afficher le reste des champs
        for (final entry in doc.entries) {
          final k = entry.key;
          if (ignoredKeys.contains(k) || primaryShown.contains(k)) continue;
          
          // Ne pas réafficher les champs couverts par alias
          bool covered = false;
          for (final keys in aliases.values) {
            if (keys.contains(k)) { covered = true; break; }
          }
          if (covered) continue;

          final fv = _formatValue(entry.value);
          if (fv.isEmpty) continue;

          // Formater la clé en label lisible
          final readableKey = k
              .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
              .replaceAll('_', ' ')
              .trim();
          final label = readableKey.isEmpty
              ? 'Champ'
              : readableKey[0].toUpperCase() + readableKey.substring(1).toLowerCase();
          buffer.writeln('$label: $fv');
        }

        buffer.writeln();
      }
      contexte = buffer.toString().trim();
    } else {
      contexte = 'Aucune information trouvée dans la base de données.';
    }

    print('Contexte construit:\n$contexte');
    return contexte;
  }

  /// Formate la réponse de Gemini (nettoyage mineur)
  String _formatResponseForUser(String response) {
    if (response.isEmpty) {
      return 'Pas de réponse reçue';
    }

    // Nettoyer les caractères spéciaux
    String formatted = response
        .replaceAll('\\n', '\n')
        .replaceAll('\\t', '  ')
        .trim();

    // Remplacer les tirets par des puces si c'est une liste
    formatted = formatted.replaceAllMapped(
      RegExp(r'^-\s+', multiLine: true),
      (match) => '• ',
    );

    return formatted;
  }

  /// Envoie un message avec le contexte Firebase pertinent
  Future<String> sendMessageWithContext(String userMessage) async {
    try {
      // Sauvegarder le message utilisateur dans l'historique
      await _historyService.addUserMessage(userMessage);

      // Construire le contexte Firebase avec recherche intelligente
      final context = await _buildFirebaseContextWithSearch(userMessage);

      // Prompt simplifié pour Gemini
      final fullPrompt = '''Tu es un assistant intelligent et chaleureux.

L'utilisateur a posé la question suivante:
"$userMessage"

Voici les informations trouvées dans la base Firestore:
$context

Formule une réponse naturelle et fluide en français (2 à 4 phrases max).
Ne fais pas de liste ni de puces.
Donne juste une explication claire comme si tu parlais à une personne.
Utilise UNIQUEMENT les informations fournies.
Si l'information n'existe pas, dis simplement: "Je n'ai pas cette information".
''';

      print('Prompt complet envoyé à Gemini:\n$fullPrompt\n---');

      // Envoyer à Gemini
      final response = await _chatSession.sendMessage(
        Content.text(fullPrompt),
      );

      final responseText = response.text ?? 'Pas de réponse reçue';
      
      print('Réponse brute de Gemini: $responseText');

      // Formater la réponse en langage naturel lisible
      final formattedResponse = _formatResponseForUser(responseText);
      
      print('Réponse formatée: $formattedResponse');

      // Sauvegarder la réponse dans l'historique local
      await _historyService.addAssistantMessage(formattedResponse);

      // Optionnel: Sauvegarder la réponse dans Firebase
      await _saveResponseToFirebase(userMessage, responseText);

      return formattedResponse;
    } catch (e) {
      print('Erreur lors de sendMessageWithContext: $e');
      return 'Erreur: ${e.toString()}';
    }
  }

  /// Sauvegarde la réponse dans Firebase (optionnel)
  Future<void> _saveResponseToFirebase(
      String question, String response) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'lastAIInteraction': {
          'question': question,
          'response': response,
          'timestamp': FieldValue.serverTimestamp(),
        }
      });
    } catch (e) {
      // Silencieusement ignorer les erreurs de sauvegarde
      print('Erreur lors de la sauvegarde: $e');
    }
  }

  /// Obtenir l'historique des messages
  List<ChatMessage> getChatHistory() {
    return _historyService.getMessages();
  }

  /// Obtenir les N derniers messages
  List<ChatMessage> getLastMessages(int count) {
    return _historyService.getLastMessages(count);
  }

  /// Effacer tout l'historique
  Future<void> clearChatHistory() async {
    await _historyService.clearHistory();
  }

  /// Exporter l'historique en texte
  String exportChatHistoryAsText() {
    return _historyService.exportAsText();
  }

  /// Exporter l'historique en JSON
  String exportChatHistoryAsJson() {
    return _historyService.exportAsJson();
  }

  /// Réinitialise la session de chat
  void resetChat() {
    _chatSession = _model.startChat();
  }

  /// Obtient l'historique du chat Gemini (session courante)
  List<Content> getGeminiChatHistory() {
    return _chatSession.history.toList();
  }
}
