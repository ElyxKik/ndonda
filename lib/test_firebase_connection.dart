import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

/// Page de test pour vérifier la connexion Firebase et lister les collections
class TestFirebaseConnection extends StatefulWidget {
  const TestFirebaseConnection({super.key});

  @override
  State<TestFirebaseConnection> createState() => _TestFirebaseConnectionState();
}

class _TestFirebaseConnectionState extends State<TestFirebaseConnection> {
  bool _isLoading = true;
  String _status = 'Connexion à Firebase...';
  Map<String, int> _collections = {};
  String _error = '';

  @override
  void initState() {
    super.initState();
    _checkFirebase();
  }

  Future<void> _checkFirebase() async {
    try {
      setState(() {
        _status = '🔄 Vérification de Firebase...';
        _isLoading = true;
      });

      // Vérifier les collections
      final firestore = FirebaseFirestore.instance;
      
      final collectionsToCheck = [
        'users',
        'projects',
        'incidents',
        'equipements',
        'dechets',
        'sensibilisations',
        'contentieux',
        'personnel',
      ];

      Map<String, int> results = {};

      for (var collectionName in collectionsToCheck) {
        try {
          final snapshot = await firestore.collection(collectionName).get();
          results[collectionName] = snapshot.docs.length;
        } catch (e) {
          results[collectionName] = -1; // Erreur
        }
      }

      setState(() {
        _collections = results;
        _status = '✅ Connecté à Firebase';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _status = '❌ Erreur de connexion';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Connexion Firebase'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statut
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _status,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (_error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Erreur: $_error',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Collections
            if (!_isLoading && _collections.isNotEmpty) ...[
              const Text(
                'Collections Firestore:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _collections.length,
                  itemBuilder: (context, index) {
                    final entry = _collections.entries.elementAt(index);
                    final collectionName = entry.key;
                    final docCount = entry.value;

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          docCount > 0
                              ? Icons.check_circle
                              : docCount == 0
                                  ? Icons.folder_open
                                  : Icons.error,
                          color: docCount > 0
                              ? Colors.green
                              : docCount == 0
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                        title: Text(collectionName),
                        subtitle: Text(
                          docCount > 0
                              ? '$docCount document(s)'
                              : docCount == 0
                                  ? 'Collection vide'
                                  : 'Erreur',
                        ),
                        trailing: docCount > 0
                            ? Chip(
                                label: Text('$docCount'),
                                backgroundColor: Colors.green.shade100,
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _checkFirebase,
                icon: const Icon(Icons.refresh),
                label: const Text('Rafraîchir'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fonction main pour tester directement
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MaterialApp(
    home: TestFirebaseConnection(),
    debugShowCheckedModeBanner: false,
  ));
}
