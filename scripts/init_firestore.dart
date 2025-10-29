import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

/// Script pour initialiser et vérifier le schéma Firestore
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

  print('📊 Vérification du schéma Firestore...\n');

  // Liste des collections attendues
  final expectedCollections = [
    'users',
    'projects',
    'incidents',
    'equipements',
    'dechets',
    'sensibilisations',
    'contentieux',
    'personnel',
  ];

  print('Collections attendues:');
  for (var collection in expectedCollections) {
    print('  - $collection');
  }
  print('');

  // Vérifier les collections existantes
  print('🔍 Vérification des collections existantes...\n');
  
  for (var collectionName in expectedCollections) {
    try {
      final snapshot = await firestore
          .collection(collectionName)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        print('⚠️  Collection "$collectionName": existe mais vide');
      } else {
        print('✅ Collection "$collectionName": ${snapshot.docs.length} document(s) trouvé(s)');
        
        // Afficher la structure du premier document
        final firstDoc = snapshot.docs.first;
        print('   Structure du document:');
        firstDoc.data().forEach((key, value) {
          print('     - $key: ${value.runtimeType}');
        });
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification de "$collectionName": $e');
    }
    print('');
  }

  // Statistiques globales
  print('📈 Statistiques globales:\n');
  
  for (var collectionName in expectedCollections) {
    try {
      final snapshot = await firestore.collection(collectionName).get();
      print('  $collectionName: ${snapshot.docs.length} document(s)');
    } catch (e) {
      print('  $collectionName: Erreur - $e');
    }
  }

  print('\n✨ Vérification terminée!');
  exit(0);
}
