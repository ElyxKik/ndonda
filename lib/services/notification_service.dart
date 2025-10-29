import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service de gestion des notifications push
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _initialized = false;

  /// Initialiser le service de notifications
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Demander la permission pour les notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Permission notifications accordée');

        // Obtenir le token FCM
        String? token = await _messaging.getToken();
        if (token != null) {
          print('📱 FCM Token: $token');
          await _saveTokenToFirestore(token);
        }

        // Écouter les changements de token
        _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

        // Gérer les messages en foreground
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Gérer les messages quand l'app est en background
        FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

        // Vérifier si l'app a été ouverte depuis une notification
        RemoteMessage? initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleBackgroundMessage(initialMessage);
        }

        _initialized = true;
        print('✅ Service de notifications initialisé');
      } else {
        print('⚠️ Permission notifications refusée');
      }
    } catch (e) {
      print('❌ Erreur initialisation notifications: $e');
    }
  }

  /// Sauvegarder le token FCM dans Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ Token FCM sauvegardé');
      }
    } catch (e) {
      print('⚠️ Erreur sauvegarde token: $e');
    }
  }

  /// Gérer les messages en foreground (app ouverte)
  void _handleForegroundMessage(RemoteMessage message) {
    print('📍 Message reçu en foreground: ${message.notification?.title}');
  }

  /// Gérer les messages en background (app fermée/minimisée)
  void _handleBackgroundMessage(RemoteMessage message) {
    print('📩 Message reçu en background: ${message.notification?.title}');
    // Gérer la navigation ou autres actions
  }


  /// Envoyer une notification à tous les utilisateurs
  Future<void> sendNotificationToAll({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Récupérer tous les tokens FCM
      final usersSnapshot = await _firestore
          .collection('users')
          .where('fcmToken', isNotEqualTo: null)
          .get();

      for (var doc in usersSnapshot.docs) {
        final token = doc.data()['fcmToken'] as String?;
        if (token != null) {
          // Note: L'envoi de notifications nécessite un serveur backend
          // ou Firebase Cloud Functions
          print('📤 Notification à envoyer à: ${doc.id}');
        }
      }
    } catch (e) {
      print('❌ Erreur envoi notifications: $e');
    }
  }

  /// Créer un déclencheur de notification pour les nouvelles données
  Future<void> setupDataListeners() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Écouter les nouveaux incidents
    _firestore
        .collection('projects')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          final projectName = data?['nom'] ?? 'Nouveau projet';
        }
      }
    });
  }

}

/// Handler pour les messages en background (doit être top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Message background: ${message.notification?.title}');
}
