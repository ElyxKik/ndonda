import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../lib/firebase_options.dart';

/// Script pour créer des données de test dans Firestore
void main() async {
  print('🚀 Initialisation de Firebase...');
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialisé avec succès\n');
  } catch (e) {
    print('❌ Erreur lors de l\'initialisation de Firebase: $e');
    exit(1);
  }

  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  print('🔐 Connexion anonyme...');
  UserCredential? userCredential;
  try {
    userCredential = await auth.signInAnonymously();
    print('✅ Connecté en tant que: ${userCredential.user?.uid}\n');
  } catch (e) {
    print('❌ Erreur de connexion: $e');
    exit(1);
  }

  final userId = userCredential.user!.uid;
  final now = DateTime.now();

  print('📝 Création des données de test...\n');

  // 1. Créer un utilisateur de test
  print('1️⃣  Création de l\'utilisateur de test...');
  try {
    await firestore.collection('users').doc(userId).set({
      'id': userId,
      'displayName': 'Utilisateur Test',
      'email': 'test@ndonda.app',
      'role': 'user',
      'organization': 'Ndonda Verte SARL',
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'lastLoginAt': now.toIso8601String(),
    });
    print('   ✅ Utilisateur créé\n');
  } catch (e) {
    print('   ❌ Erreur: $e\n');
  }

  // 2. Créer un projet de test
  print('2️⃣  Création d\'un projet de test...');
  String? projectId;
  try {
    final projectRef = await firestore.collection('projects').add({
      'nom': 'Projet Test - Construction Route',
      'localisation': 'Kinshasa, RDC',
      'latitude': -4.3276,
      'longitude': 15.3136,
      'dateDebut': now.subtract(Duration(days: 30)).toIso8601String(),
      'dateFin': now.add(Duration(days: 335)).toIso8601String(),
      'statut': 'en_cours',
      'description': 'Projet de test pour la construction d\'une route',
      'budget': 1000000,
      'client': 'Client Test',
      'userId': userId,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'archived': false,
    });
    projectId = projectRef.id;
    print('   ✅ Projet créé avec ID: $projectId\n');
  } catch (e) {
    print('   ❌ Erreur: $e\n');
    exit(1);
  }

  // 3. Créer un incident de test
  print('3️⃣  Création d\'un incident de test...');
  try {
    await firestore.collection('incidents').add({
      'projectId': projectId,
      'date': now.subtract(Duration(days: 5)).toIso8601String(),
      'type': 'accident_travail',
      'gravite': 'moyen',
      'description': 'Chute de hauteur lors de travaux',
      'personneAffectee': 'Jean Test',
      'fonction': 'Ouvrier',
      'mesuresPrises': 'Premiers soins et transport à l\'hôpital',
      'joursArretTravail': 7,
      'localisation': 'Chantier Zone A',
      'photos': [],
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'createdBy': userId,
    });
    print('   ✅ Incident créé\n');
  } catch (e) {
    print('   ❌ Erreur: $e\n');
  }

  // 4. Créer un équipement de test
  print('4️⃣  Création d\'un équipement de test...');
  try {
    await firestore.collection('equipements').add({
      'projectId': projectId,
      'date': now.subtract(Duration(days: 10)).toIso8601String(),
      'typeEquipement': 'EPI',
      'designation': 'Casque de sécurité',
      'quantiteDemandee': 50,
      'quantiteFournie': 50,
      'fournisseur': 'SafetyPro SARL',
      'statut': 'Fourni',
      'photos': [],
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'createdBy': userId,
    });
    print('   ✅ Équipement créé\n');
  } catch (e) {
    print('   ❌ Erreur: $e\n');
  }

  // 5. Créer un déchet de test
  print('5️⃣  Création d\'un déchet de test...');
  try {
    await firestore.collection('dechets').add({
      'projectId': projectId,
      'date': now.subtract(Duration(days: 3)).toIso8601String(),
      'typeDechet': 'recyclable',
      'description': 'Déchets métalliques',
      'quantite': 2.5,
      'unite': 'tonnes',
      'modeGestion': 'recyclage',
      'destination': 'Centre de recyclage',
      'photos': [],
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'createdBy': userId,
    });
    print('   ✅ Déchet créé\n');
  } catch (e) {
    print('   ❌ Erreur: $e\n');
  }

  // 6. Créer une sensibilisation de test
  print('6️⃣  Création d\'une sensibilisation de test...');
  try {
    await firestore.collection('sensibilisations').add({
      'projectId': projectId,
      'date': now.subtract(Duration(days: 7)).toIso8601String(),
      'theme': 'VIH_SIDA',
      'type': 'formation',
      'nombreParticipants': 45,
      'nombreHommes': 30,
      'nombreFemmes': 15,
      'intervenant': 'Dr. Test',
      'materielDistribue': 'Brochures',
      'quantiteMateriel': 100,
      'photos': [],
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'createdBy': userId,
    });
    print('   ✅ Sensibilisation créée\n');
  } catch (e) {
    print('   ❌ Erreur: $e\n');
  }

  // 7. Créer un contentieux de test
  print('7️⃣  Création d\'un contentieux de test...');
  try {
    await firestore.collection('contentieux').add({
      'projectId': projectId,
      'dateOuverture': now.subtract(Duration(days: 20)).toIso8601String(),
      'objet': 'Litige foncier test',
      'parties': 'Entreprise vs Propriétaire',
      'nature': 'foncier',
      'statut': 'En cours',
      'photos': [],
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'createdBy': userId,
    });
    print('   ✅ Contentieux créé\n');
  } catch (e) {
    print('   ❌ Erreur: $e\n');
  }

  // 8. Créer un personnel de test
  print('8️⃣  Création d\'un personnel de test...');
  try {
    await firestore.collection('personnel').add({
      'projectId': projectId,
      'date': now.toIso8601String(),
      'nombreOuvriers': 120,
      'nombreCadres': 15,
      'nombreRiverain': 30,
      'totalPersonnel': 165,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'createdBy': userId,
    });
    print('   ✅ Personnel créé\n');
  } catch (e) {
    print('   ❌ Erreur: $e\n');
  }

  print('✨ Données de test créées avec succès!');
  print('\n📊 Résumé:');
  print('  - 1 utilisateur');
  print('  - 1 projet');
  print('  - 1 incident');
  print('  - 1 équipement');
  print('  - 1 déchet');
  print('  - 1 sensibilisation');
  print('  - 1 contentieux');
  print('  - 1 personnel');
  
  exit(0);
}
