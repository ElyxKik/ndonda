#!/bin/bash

# Script de configuration pour NDONDA VERTE Report Builder
# Ce script configure automatiquement le projet Flutter

echo "🌿 NDONDA VERTE Report Builder - Configuration"
echo "=============================================="
echo ""

# Vérifier si Flutter est installé
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter n'est pas installé!"
    echo "📥 Téléchargez Flutter depuis: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter détecté: $(flutter --version | head -n 1)"
echo ""

# Nettoyer le projet
echo "🧹 Nettoyage du projet..."
flutter clean

# Installer les dépendances
echo "📦 Installation des dépendances..."
flutter pub get

# Créer les dossiers assets s'ils n'existent pas
echo "📁 Création des dossiers assets..."
mkdir -p assets/images
mkdir -p assets/icons

# Créer les plateformes si nécessaire
echo "🔧 Configuration des plateformes..."

# Android
if [ ! -d "android" ]; then
    echo "📱 Création de la plateforme Android..."
    flutter create --platforms=android .
fi

# iOS (seulement sur macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    if [ ! -d "ios" ]; then
        echo "🍎 Création de la plateforme iOS..."
        flutter create --platforms=ios .
        cd ios
        pod install
        cd ..
    fi
fi

# Web
if [ ! -d "web" ]; then
    echo "🌐 Création de la plateforme Web..."
    flutter create --platforms=web .
fi

# Vérifier la configuration
echo ""
echo "🔍 Vérification de la configuration..."
flutter doctor

echo ""
echo "✅ Configuration terminée!"
echo ""
echo "🚀 Pour lancer l'application:"
echo "   - Mobile: flutter run"
echo "   - Web: flutter run -d chrome"
echo ""
echo "📖 Consultez INSTALLATION.md pour plus d'informations"
