#!/bin/bash

# Script de build Android pour Ndonda Verte
# Usage: ./build_android.sh [apk|appbundle|split]

set -e

echo "🚀 Build Android - Ndonda Verte"
echo "================================"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Type de build (par défaut: apk)
BUILD_TYPE=${1:-apk}

# Nettoyer avant le build
echo -e "${BLUE}🧹 Nettoyage...${NC}"
flutter clean
flutter pub get

# Build selon le type
case $BUILD_TYPE in
  apk)
    echo -e "${BLUE}📦 Build APK Standard...${NC}"
    flutter build apk --release
    OUTPUT_PATH="build/app/outputs/flutter-apk/app-release.apk"
    ;;
    
  split)
    echo -e "${BLUE}📦 Build APK Split par ABI...${NC}"
    flutter build apk --split-per-abi --release
    OUTPUT_PATH="build/app/outputs/flutter-apk/"
    ;;
    
  appbundle)
    echo -e "${BLUE}📦 Build App Bundle (Google Play)...${NC}"
    flutter build appbundle --release
    OUTPUT_PATH="build/app/outputs/bundle/release/app-release.aab"
    ;;
    
  *)
    echo -e "${RED}❌ Type de build invalide: $BUILD_TYPE${NC}"
    echo "Usage: ./build_android.sh [apk|appbundle|split]"
    exit 1
    ;;
esac

# Vérifier le succès
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build réussi!${NC}"
    echo ""
    echo -e "${YELLOW}📍 Fichier(s) généré(s):${NC}"
    
    if [ "$BUILD_TYPE" = "split" ]; then
        ls -lh build/app/outputs/flutter-apk/*.apk
    else
        ls -lh $OUTPUT_PATH
    fi
    
    echo ""
    echo -e "${BLUE}📱 Pour installer sur un appareil:${NC}"
    if [ "$BUILD_TYPE" = "appbundle" ]; then
        echo "   Uploader sur Google Play Console"
    else
        echo "   adb install $OUTPUT_PATH"
    fi
    
    # Ouvrir le dossier
    echo ""
    echo -e "${BLUE}📂 Ouvrir le dossier de sortie?${NC}"
    read -p "   (o/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Oo]$ ]]; then
        if [ "$BUILD_TYPE" = "split" ]; then
            open build/app/outputs/flutter-apk/
        else
            open $(dirname $OUTPUT_PATH)
        fi
    fi
else
    echo -e "${RED}❌ Build échoué!${NC}"
    exit 1
fi
