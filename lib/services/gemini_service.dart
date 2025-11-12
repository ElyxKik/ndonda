import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/gemini_config.dart';

class GeminiService {
  late GenerativeModel _model;
  late ChatSession _chatSession;

  GeminiService() {
    if (!GeminiConfig.isConfigured()) {
      throw Exception(
        'Clé API Gemini non configurée. '
        'Veuillez configurer votre clé API dans lib/config/gemini_config.dart'
      );
    }
    
    _model = GenerativeModel(
      model: GeminiConfig.model,
      apiKey: GeminiConfig.apiKey,
    );
    _chatSession = _model.startChat();
  }

  /// Envoie un message et reçoit une réponse
  Future<String> sendMessage(String message) async {
    try {
      final response = await _chatSession.sendMessage(
        Content.text(message),
      );
      
      return response.text ?? 'Pas de réponse reçue';
    } catch (e) {
      return 'Erreur: ${e.toString()}';
    }
  }

  /// Réinitialise la session de chat
  void resetChat() {
    _chatSession = _model.startChat();
  }

  /// Obtient l'historique du chat
  List<Content> getChatHistory() {
    return _chatSession.history.toList();
  }
}
