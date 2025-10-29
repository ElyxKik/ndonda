import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

/// Script simple pour lister toutes les collections Firestore
void main() async {
  print('🚀 Connexion à Firebase...\n');
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Connecté au projet Firebase\n');
  } catch (e) {
    print('❌ Erreur de connexion: $e');
    exit(1);
  }

  final firestore = FirebaseFirestore.instance;

  print('📊 Analyse des collections Firestore...\n');
  print('=' * 60);

  // Liste des collections à vérifier
  final collectionsToCheck = [
    'users',
    'projects',
    'incidents',
    'equipements',
    'dechets',
    'sensibilisations',
    'contentieux',
    'personnel',
    'project_stats',
  ];

  int totalDocuments = 0;
  List<String> existingCollections = [];
  List<String> emptyCollections = [];

  for (var collectionName in collectionsToCheck) {
    try {
      final snapshot = await firestore.collection(collectionName).get();
      final docCount = snapshot.docs.length;
      
      if (docCount > 0) {
        existingCollections.add(collectionName);
        totalDocuments += docCount;
        
        print('\n✅ Collection: $collectionName');
        print('   Documents: $docCount');
        
        // Afficher un exemple de document
        if (snapshot.docs.isNotEmpty) {
          final firstDoc = snapshot.docs.first;
          print('   Exemple de structure:');
          
          final data = firstDoc.data();
          final keys = data.keys.toList()..sort();
          
          for (var key in keys.take(10)) { // Limiter à 10 champs
            final value = data[key];
            final type = value.runtimeType.toString();
            print('     • $key: $type');
          }
          
          if (keys.length > 10) {
            print('     ... et ${keys.length - 10} autres champs');
          }
        }
      } else {
        emptyCollections.add(collectionName);
      }
    } catch (e) {
      print('\n⚠️  Collection: $collectionName');
      print('   Erreur: $e');
    }
  }

  print('\n' + '=' * 60);
  print('\n📈 RÉSUMÉ\n');
  print('Collections avec données: ${existingCollections.length}');
  for (var col in existingCollections) {
    print('  ✓ $col');
  }
  
  if (emptyCollections.isNotEmpty) {
    print('\nCollections vides: ${emptyCollections.length}');
    for (var col in emptyCollections) {
      print('  ○ $col');
    }
  }
  
  print('\nTotal de documents: $totalDocuments');
  print('\n' + '=' * 60);
  
  exit(0);
}
