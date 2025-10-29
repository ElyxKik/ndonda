#!/bin/bash

# Script pour configurer Google Sign-In pour le Web
# Usage: ./setup_google_signin_web.sh VOTRE_CLIENT_ID

if [ -z "$1" ]; then
    echo "❌ Erreur : Client ID manquant"
    echo ""
    echo "Usage: ./setup_google_signin_web.sh VOTRE_CLIENT_ID"
    echo ""
    echo "Pour obtenir votre Client ID :"
    echo "1. Allez sur https://console.cloud.google.com/"
    echo "2. Sélectionnez votre projet 'ndonda-verte-62700'"
    echo "3. APIs & Services > Credentials"
    echo "4. Copiez le 'OAuth 2.0 Client ID' de type 'Web client'"
    echo ""
    exit 1
fi

CLIENT_ID=$1
INDEX_FILE="web/index.html"

echo "🔧 Configuration de Google Sign-In pour le Web..."
echo ""

# Vérifier que le fichier existe
if [ ! -f "$INDEX_FILE" ]; then
    echo "❌ Erreur : $INDEX_FILE n'existe pas"
    exit 1
fi

# Créer une sauvegarde
cp "$INDEX_FILE" "${INDEX_FILE}.backup"
echo "✅ Sauvegarde créée : ${INDEX_FILE}.backup"

# Vérifier si la balise meta existe déjà
if grep -q "google-signin-client_id" "$INDEX_FILE"; then
    echo "⚠️  La balise meta Google Sign-In existe déjà"
    echo "   Mise à jour du Client ID..."
    # Remplacer l'ancien Client ID
    sed -i.tmp "s|<meta name=\"google-signin-client_id\" content=\"[^\"]*\">|<meta name=\"google-signin-client_id\" content=\"$CLIENT_ID\">|" "$INDEX_FILE"
    rm "${INDEX_FILE}.tmp"
else
    echo "➕ Ajout de la balise meta Google Sign-In..."
    # Ajouter la balise meta après la balise description
    sed -i.tmp "/<meta name=\"description\"/a\\
  \\
  <!-- Google Sign-In Client ID -->\\
  <meta name=\"google-signin-client_id\" content=\"$CLIENT_ID\">
" "$INDEX_FILE"
    rm "${INDEX_FILE}.tmp"
fi

echo ""
echo "✅ Configuration terminée !"
echo ""
echo "📋 Prochaines étapes :"
echo "1. Vérifiez que Google Sign-In est activé dans Firebase Console"
echo "2. Vérifiez que 'localhost' est dans les domaines autorisés"
echo "3. Redémarrez l'application :"
echo "   flutter clean"
echo "   flutter run -d chrome"
echo ""
echo "📖 Pour plus d'informations, consultez SETUP_GOOGLE_SIGNIN.md"
