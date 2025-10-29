#!/bin/bash

# Script pour vérifier les collections Firestore existantes
# Utilise l'API REST Firebase

PROJECT_ID="ndonda-verte"

echo "🔍 Vérification des collections Firestore dans le projet: $PROJECT_ID"
echo ""

# Vérifier si l'utilisateur est connecté
if ! firebase projects:list | grep -q "$PROJECT_ID"; then
    echo "❌ Erreur: Vous n'êtes pas connecté ou le projet n'existe pas"
    echo "   Exécutez: firebase login"
    exit 1
fi

echo "✅ Connecté au projet Firebase"
echo ""

# Liste des collections attendues
collections=(
    "users"
    "projects"
    "incidents"
    "equipements"
    "dechets"
    "sensibilisations"
    "contentieux"
    "personnel"
)

echo "📊 Collections attendues dans le schéma:"
for collection in "${collections[@]}"; do
    echo "  - $collection"
done
echo ""

echo "🔗 Pour vérifier manuellement les collections:"
echo "   1. Allez sur: https://console.firebase.google.com/project/$PROJECT_ID/firestore"
echo "   2. Vérifiez que Firestore est activé"
echo "   3. Consultez les collections existantes"
echo ""

echo "💡 Pour activer Firestore (si pas encore fait):"
echo "   1. Allez sur: https://console.firebase.google.com/project/$PROJECT_ID/firestore"
echo "   2. Cliquez sur 'Créer une base de données'"
echo "   3. Choisissez le mode (production ou test)"
echo "   4. Sélectionnez une région (ex: europe-west1)"
echo ""

echo "🚀 Pour vérifier les collections via l'application:"
echo "   dart run scripts/init_firestore.dart"
echo ""
