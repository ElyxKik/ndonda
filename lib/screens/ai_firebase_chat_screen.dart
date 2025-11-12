import 'package:flutter/material.dart';
import '../services/firebase_gemini_service.dart';
import '../services/conversation_history_service.dart';
import '../widgets/conversation_history_modal.dart';
import '../utils/constants.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}

class AIFirebaseChatScreen extends StatefulWidget {
  const AIFirebaseChatScreen({super.key});

  @override
  State<AIFirebaseChatScreen> createState() => _AIFirebaseChatScreenState();
}

class _AIFirebaseChatScreenState extends State<AIFirebaseChatScreen> {
  FirebaseGeminiService? _geminiService;
  String? _initError;
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  final ConversationHistoryService _historyService =
      ConversationHistoryService();
  String? _currentConversationId;
  bool _conversationStarted = false;

  @override
  void initState() {
    super.initState();
    _initializeGemini();
  }

  void _initializeGemini() async {
    try {
      _geminiService = FirebaseGeminiService();
      await _geminiService!.initialize();
      _addWelcomeMessage();
    } catch (e) {
      setState(() {
        _initError = e.toString();
      });
    }
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        Message(
          text:
              'Bonjour! 👋 Je suis votre assistant IA intelligent. Je peux accéder à vos données dans ENVIROX et répondre à vos questions basées sur ces informations. Que puis-je faire pour vous?',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _sendMessage() async {
    if (_geminiService == null) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Créer une conversation si c'est le premier message
    if (!_conversationStarted) {
      try {
        final title = _historyService.generateTitle(text);
        _currentConversationId =
            await _historyService.createConversation(
          type: 'firebase',
          title: title,
        );
        _conversationStarted = true;
        print('✅ Conversation créée: $_currentConversationId');
      } catch (e) {
        print('❌ Erreur création conversation: $e');
      }
    }

    // Ajouter le message de l'utilisateur
    setState(() {
      _messages.add(
        Message(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });

    // Sauvegarder le message utilisateur
    if (_currentConversationId != null) {
      try {
        await _historyService.addMessage(
          conversationId: _currentConversationId!,
          role: 'user',
          content: text,
        );
      } catch (e) {
        print('❌ Erreur sauvegarde message utilisateur: $e');
      }
    }

    _messageController.clear();
    _scrollToBottom();

    try {
      // Obtenir la réponse de Gemini avec le contexte Firebase
      final response = await _geminiService!.sendMessageWithContext(text);

      setState(() {
        _messages.add(
          Message(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });

      // Sauvegarder le message assistant
      if (_currentConversationId != null) {
        try {
          await _historyService.addMessage(
            conversationId: _currentConversationId!,
            role: 'assistant',
            content: response,
          );
        } catch (e) {
          print('❌ Erreur sauvegarde message assistant: $e');
        }
      }
    } catch (e) {
      setState(() {
        _messages.add(
          Message(
            text: 'Erreur: ${e.toString()}',
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _resetChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser le chat'),
        content: const Text(
            'Êtes-vous sûr de vouloir effacer tout l\'historique du chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              _geminiService?.resetChat();
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
              Navigator.pop(context);
            },
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Assistant IA (Données Firebase)'),
        elevation: 0,
        actions: [
          if (_geminiService != null)
            IconButton(
              icon: const Icon(Icons.history_rounded),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) =>
                      const ConversationHistoryModal(chatType: 'firebase'),
                );
              },
              tooltip: 'Historique des conversations',
            ),
          if (_geminiService != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _resetChat,
              tooltip: 'Réinitialiser le chat',
            ),
        ],
      ),
      body: _initError != null
          ? _buildErrorScreen()
          : Column(
              children: [
                // Messages
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_rounded,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun message',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return _buildMessageBubble(message);
                          },
                        ),
                ),
                // Indicateur de chargement
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'L\'assistant analyse vos données...',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // Zone de saisie
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Posez votre question...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                            maxLines: null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                            ),
                            onPressed: _isLoading ? null : _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'Configuration requise',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _initError ?? 'Erreur inconnue',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade900,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Étapes pour configurer:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Allez sur https://ai.google.dev\n'
                    '2. Créez une clé API Gemini\n'
                    '3. Ouvrez lib/config/gemini_config.dart\n'
                    '4. Remplacez YOUR_GEMINI_API_KEY par votre clé\n'
                    '5. Redémarrez l\'application',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: message.isError
                    ? Colors.red.shade100
                    : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                message.isError ? Icons.error_rounded : Icons.smart_toy_rounded,
                size: 18,
                color: message.isError ? Colors.red : AppColors.primary,
              ),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.primary
                    : message.isError
                        ? Colors.red.shade50
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: message.isError
                    ? Border.all(color: Colors.red.shade200)
                    : null,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser
                      ? Colors.white
                      : message.isError
                          ? Colors.red.shade900
                          : Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (message.isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
