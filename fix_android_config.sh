#!/bin/bash

# Script pour corriger la configuration Android

echo "🔧 Correction de la configuration Android..."

# 1. Mettre à jour le minSdkVersion dans build.gradle.kts
echo "📝 Mise à jour du minSdkVersion à 23..."

# Fichier build.gradle.kts de l'app
APP_BUILD_FILE="android/app/build.gradle.kts"

if [ -f "$APP_BUILD_FILE" ]; then
    # Remplacer minSdk = 21 par minSdk = 23
    sed -i '' 's/minSdk = 21/minSdk = 23/g' "$APP_BUILD_FILE"
    
    # Ajouter ndkVersion si pas déjà présent
    if ! grep -q "ndkVersion" "$APP_BUILD_FILE"; then
        # Trouver la ligne android { et ajouter ndkVersion après
        sed -i '' '/android {/a\
    ndkVersion = "27.0.12077973"
' "$APP_BUILD_FILE"
    else
        # Remplacer la version existante
        sed -i '' 's/ndkVersion = ".*"/ndkVersion = "27.0.12077973"/g' "$APP_BUILD_FILE"
    fi
    
    echo "✅ Configuration mise à jour dans $APP_BUILD_FILE"
else
    echo "❌ Fichier $APP_BUILD_FILE non trouvé"
    exit 1
fi

# 2. Nettoyer le projet
echo "🧹 Nettoyage du projet..."
flutter clean

# 3. Récupérer les dépendances
echo "📦 Récupération des dépendances..."
flutter pub get

echo ""
echo "✅ Configuration Android corrigée !"
echo ""
echo "Vous pouvez maintenant lancer la compilation avec :"
echo "  flutter build apk --release"
