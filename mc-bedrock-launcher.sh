#!/bin/bash

# Nom du script : mc-bedrock-launcher.sh
# Description : Lanceur intelligent pour BedrockOnLinux (Gère l'installation, les MAJ et le lancement)

APP_CMD="bedrock-on-linux"

echo "=== Vérification de BedrockOnLinux ==="

# 1. Vérifie si la commande/le paquet est installé
if ! command -v "$APP_CMD" &> /dev/null && ! dpkg -l | grep -q "bedrock-on-linux"; then
  echo "BedrockOnLinux n'est pas installé. Détection de la distribution..."

  # Récupération de l'API GitHub pour les assets
  API_URL="https://api.github.com/repos/Wyze3306/BedrockOnLinux/releases/latest"

  if command -v apt &> /dev/null; then
    echo "Distribution basée sur Debian/Ubuntu/Mint détectée. Installation via .deb..."
    DEB_URL=$(curl -s "$API_URL" | grep "browser_download_url" | grep "amd64.deb" | cut -d '"' -f 4)
    
    if [ -z "$DEB_URL" ]; then
      echo "Erreur : Impossible de récupérer le lien du paquet .deb."
      exit 1
    fi

    wget -O /tmp/bedrock-latest.amd64.deb "$DEB_URL"
    sudo apt install -y /tmp/bedrock-latest.amd64.deb
    rm -f /tmp/bedrock-latest.amd64.deb

  else
    echo "Autre distribution détectée. Installation via AppImage universel..."
    APPIMAGE_URL=$(curl -s "$API_URL" | grep "browser_download_url" | grep "x86_64.AppImage" | cut -d '"' -f 4)
    
    if [ -z "$APPIMAGE_URL" ]; then
      echo "Erreur : Impossible de récupérer le lien de l'AppImage."
      exit 1
    fi

    mkdir -p ~/.local/bin
    wget -O ~/.local/bin/BedrockOnLinux.AppImage "$APPIMAGE_URL"
    chmod +x ~/.local/bin/BedrockOnLinux.AppImage
    
    echo "AppImage installé dans ~/.local/bin/"
  fi

else
  echo "BedrockOnLinux est déjà installé. Vérification des mises à jour..."
  if command -v "$APP_CMD" &> /dev/null; then
    "$APP_CMD" update
  fi
fi

echo "=== Lancement du jeu ==="
if command -v "$APP_CMD" &> /dev/null; then
  "$APP_CMD" play
elif [ -f ~/.local/bin/BedrockOnLinux.AppImage ]; then
  ~/.local/bin/BedrockOnLinux.AppImage
else
  echo "Erreur : Impossible de lancer le jeu, exécutable introuvable."
  exit 1
fi