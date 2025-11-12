/// Configuration pour l'API Gemini
/// 
/// Pour utiliser l'assistant IA, vous devez:
/// 1. Obtenir une clé API Gemini depuis https://ai.google.dev
/// 2. Remplacer 'YOUR_GEMINI_API_KEY' par votre clé API
/// 3. Redémarrer l'application

class GeminiConfig {
  /// Votre clé API Gemini
  /// À obtenir depuis: https://ai.google.dev/tutorials/setup
  static const String apiKey = 'AIzaSyBaXJZOPLJ3GUg4qqawlwpu7bbL1ylz2qo';
  
  /// Le modèle Gemini à utiliser (gemini-2.5-flash-lite est le plus rapide et léger)
  static const String model = 'gemini-2.5-flash-lite';
  
  /// Vérifier si la clé API est configurée
  static bool isConfigured() {
    return apiKey.isNotEmpty && 
           apiKey != 'YOUR_GEMINI_API_KEY' &&
           apiKey.startsWith('AIza');
  }
}
