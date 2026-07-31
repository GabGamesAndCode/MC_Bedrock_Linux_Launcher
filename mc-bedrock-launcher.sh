#!/bin/bash

# Nom du script : mc-bedrock-launcher.sh
# Description : Lanceur intelligent pour BedrockOnLinux (Gère l'installation, les MAJ, le verrou anti-double-clic et le crash GPU)

# --- 0. Auto-mise à jour si le projet a été cloné via Git ---
if [ -d ".git" ]; then
  echo "Vérification des mises à jour du script via Git..."
  git pull --quiet 2>/dev/null
fi

APP_CMD="bedrock-on-linux"
LOCK_FILE="/tmp/mc_bedrock_launcher.lock"

# --- 1. Empêcher les instances multiples (Anti-double clic) ---
if [ -e "$LOCK_FILE" ]; then
  # Vérifie si le processus inscrit dans le lock tourne toujours
  OLD_PID=$(cat "$LOCK_FILE")
  if ps -p "$OLD_PID" > /dev/null 2>&1; then
    echo "Erreur : Une instance de BedrockOnLinux Launcher est déjà en cours d'exécution !"
    exit 1
  else
    # Ancien verrou orphelin, on le nettoie
    rm -f "$LOCK_FILE"
  fi
fi

# Création du verrou pour cette session
echo $$ > "$LOCK_FILE"

# Nettoyage automatique du verrou à la fermeture du script (peu importe la manière)
trap "rm -f '$LOCK_FILE'" EXIT

echo "=== Vérification de BedrockOnLinux ==="

# 2. Vérifie si la commande/le paquet est installé
if ! command -v "$APP_CMD" &> /dev/null && ! dpkg -l | grep -q "bedrock-on-linux"; then
  echo "BedrockOnLinux n'est pas installé. Détection de la distribution..."

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
  # Tente de lancer le jeu, si le verrou GPU bloque, acquitte-le automatiquement et relance
  "$APP_CMD" play
  EXIT_CODE=$?
  if [ $EXIT_CODE -ne 0 ]; then
    echo "Détection d'un plantage graphique potentiel. Récupération automatique..."
    "$APP_CMD" doctor --acknowledge-gpu-crash
    "$APP_CMD" play
  fi
elif [ -f ~/.local/bin/BedrockOnLinux.AppImage ]; then
  ~/.local/bin/BedrockOnLinux.AppImage
else
  echo "Erreur : Impossible de lancer le jeu, exécutable introuvable."
  exit 1
fi
