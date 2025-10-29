#!/bin/bash

echo "🔥 Configuration de Firebase pour Ndonda Verte"
echo "=============================================="
echo ""

# Vérifier si Firebase CLI est installé
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI n'est pas installé"
    echo "📦 Installation de Firebase CLI..."
    npm install -g firebase-tools
fi

# Vérifier si FlutterFire CLI est installé
if ! command -v flutterfire &> /dev/null; then
    echo "❌ FlutterFire CLI n'est pas installé"
    echo "📦 Installation de FlutterFire CLI..."
    dart pub global activate flutterfire_cli
fi

echo ""
echo "✅ Outils installés"
echo ""

# Se connecter à Firebase
echo "🔑 Connexion à Firebase..."
firebase login

echo ""
echo "⚙️  Configuration de Firebase pour votre projet..."
echo ""

# Configurer Firebase
flutterfire configure

echo ""
echo "✅ Configuration terminée!"
echo ""
echo "📝 Prochaines étapes:"
echo "1. Activez l'authentification anonyme dans Firebase Console"
echo "2. Vérifiez les règles de sécurité Firestore"
echo "3. Lancez l'application avec: flutter run"
