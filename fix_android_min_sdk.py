#!/usr/bin/env python3
"""
Script pour corriger la configuration Android minSdk et ndkVersion
"""

import re
import os

def update_build_gradle():
    """Met à jour android/app/build.gradle.kts"""
    file_path = "android/app/build.gradle.kts"
    
    if not os.path.exists(file_path):
        print(f"❌ Fichier {file_path} non trouvé")
        return False
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Remplacer minSdk = 21 par minSdk = 23
    content = re.sub(r'minSdk\s*=\s*21', 'minSdk = 23', content)
    content = re.sub(r'minSdkVersion\s*=\s*21', 'minSdkVersion = 23', content)
    
    # Ajouter ou remplacer ndkVersion
    if 'ndkVersion' in content:
        content = re.sub(r'ndkVersion\s*=\s*"[^"]*"', 'ndkVersion = "27.0.12077973"', content)
    else:
        # Ajouter après la ligne android {
        content = re.sub(
            r'(android\s*\{)',
            r'\1\n    ndkVersion = "27.0.12077973"',
            content
        )
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print(f"✅ {file_path} mis à jour")
    return True

def update_android_manifest():
    """Met à jour android/app/src/main/AndroidManifest.xml"""
    file_path = "android/app/src/main/AndroidManifest.xml"
    
    if not os.path.exists(file_path):
        print(f"❌ Fichier {file_path} non trouvé")
        return False
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Remplacer minSdkVersion="21" par minSdkVersion="23"
    content = re.sub(r'android:minSdkVersion="21"', 'android:minSdkVersion="23"', content)
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print(f"✅ {file_path} mis à jour")
    return True

def main():
    print("🔧 Correction de la configuration Android...")
    print()
    
    success = True
    success = update_build_gradle() and success
    success = update_android_manifest() and success
    
    print()
    if success:
        print("✅ Configuration Android corrigée avec succès !")
        print()
        print("Vous pouvez maintenant lancer :")
        print("  flutter build apk --release")
    else:
        print("❌ Certains fichiers n'ont pas pu être mis à jour")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
