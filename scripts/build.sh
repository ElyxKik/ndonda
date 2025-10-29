#!/bin/bash

# Script de build pour NDONDA VERTE Report Builder

echo "🌿 NDONDA VERTE Report Builder - Build"
echo "======================================"
echo ""

# Menu de sélection
echo "Sélectionnez la plateforme de build:"
echo "1) Android APK"
echo "2) Android App Bundle (AAB)"
echo "3) iOS"
echo "4) Web"
echo "5) Toutes les plateformes"
echo ""
read -p "Votre choix (1-5): " choice

case $choice in
    1)
        echo "📱 Build Android APK..."
        flutter build apk --release
        echo "✅ APK généré: build/app/outputs/flutter-apk/app-release.apk"
        ;;
    2)
        echo "📱 Build Android App Bundle..."
        flutter build appbundle --release
        echo "✅ AAB généré: build/app/outputs/bundle/release/app-release.aab"
        ;;
    3)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "🍎 Build iOS..."
            flutter build ios --release
            echo "✅ Build iOS terminé. Ouvrez Xcode pour archiver."
        else
            echo "❌ Build iOS disponible uniquement sur macOS"
        fi
        ;;
    4)
        echo "🌐 Build Web..."
        flutter build web --release
        echo "✅ Build Web généré: build/web/"
        ;;
    5)
        echo "🚀 Build de toutes les plateformes..."
        
        # Android APK
        echo "📱 Build Android APK..."
        flutter build apk --release
        
        # Android AAB
        echo "📱 Build Android App Bundle..."
        flutter build appbundle --release
        
        # iOS (si macOS)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "🍎 Build iOS..."
            flutter build ios --release
        fi
        
        # Web
        echo "🌐 Build Web..."
        flutter build web --release
        
        echo "✅ Tous les builds terminés!"
        ;;
    *)
        echo "❌ Choix invalide"
        exit 1
        ;;
esac

echo ""
echo "✅ Build terminé avec succès!"
