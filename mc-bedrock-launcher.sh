#!/bin/bash

# Nom du script : mc-bedrock-launcher.sh
# Description : Lanceur intelligent et universel pour BedrockOnLinux avec nettoyage GPU sécurisé

# --- 0. Auto-mise à jour sécurisée via Git ---
if [ -d ".git" ] && git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "Vérification des mises à jour du script via Git..."
  git pull --quiet 2>/dev/null
fi

LOCK_FILE="/tmp/mc_bedrock_launcher.lock"

# --- 1. Empêcher les instances multiples (Anti-double clic) ---
if [ -e "$LOCK_FILE" ]; then
  OLD_PID=$(cat "$LOCK_FILE")
  if ps -p "$OLD_PID" > /dev/null 2>&1; then
    echo "Erreur : Une instance de BedrockOnLinux Launcher est déjà en cours d'exécution !"
    exit 1
  else
    rm -f "$LOCK_FILE"
  fi
fi

echo $$ > "$LOCK_FILE"
trap "rm -f '$LOCK_FILE'" EXIT

echo "=== Configuration de l'environnement ==="
# S'assurer que le dossier local bin est dans le PATH (essentiel pour l'AppImage)
export PATH="$HOME/.local/bin:$PATH"
APP_CMD="bedrock-on-linux"

# --- 2. Détection dynamique de la carte graphique (Multi-ordinateurs) ---
# Cette section applique les optimisations uniquement si l'ordinateur possède une puce graphique Intel Iris/UHD.
if lshw -C display 2>/dev/null | grep -qi "intel"; then
  echo "GPU Intel détecté : Application des optimisations Iris."
  export MESA_LOADER_DRIVER_OVERRIDE=iris
  export MESA_VK_WSI_PRESENT_MODE=immediate
else
  echo "GPU AMD/NVIDIA ou autre détecté : Utilisation des pilotes système par défaut."
fi

# Correction Proton globale pour éviter le saut des correctifs automatiques
export PROTON_FIXES_FORCE=1

# --- 3. Vérification et Installation/Mise à jour ---
if ! command -v "$APP_CMD" &> /dev/null && ! dpkg -l | grep -q "bedrock-on-linux"; then
  echo "BedrockOnLinux n'est pas installé. Détection de la distribution..."
  API_URL="https://api.github.com/repos/Wyze3306/BedrockOnLinux/releases/latest"

  if command -v apt &> /dev/null; then
    echo "Distribution basée sur Debian/Ubuntu/Mint détectée. Installation via .deb..."
    DEB_URL=$(curl -s "$API_URL" | grep "browser_download_url" | grep "amd64.deb" | cut -d '"' -f 4)
    if [ -z "$DEB_URL" ]; then echo "Erreur : Impossible de récupérer le .deb."; exit 1; fi

    wget -O /tmp/bedrock-latest.amd64.deb "$DEB_URL"
    sudo apt update && sudo apt install -y /tmp/bedrock-latest.amd64.deb
    rm -f /tmp/bedrock-latest.amd64.deb
  else
    echo "Autre distribution détectée. Installation via AppImage universel..."
    APPIMAGE_URL=$(curl -s "$API_URL" | grep "browser_download_url" | grep "x86_64.AppImage" | cut -d '"' -f 4)
    if [ -z "$APPIMAGE_URL" ]; then echo "Erreur : Impossible de récupérer l'AppImage."; exit 1; fi

    mkdir -p ~/.local/bin
    # On le nomme 'bedrock-on-linux' pour que l'AppImage réponde à la même commande que le .deb
    wget -O ~/.local/bin/bedrock-on-linux "$APPIMAGE_URL"
    chmod +x ~/.local/bin/bedrock-on-linux
    echo "AppImage installé dans ~/.local/bin/bedrock-on-linux"
  fi
else
  echo "BedrockOnLinux est déjà installé. Vérification des mises à jour..."
  "$APP_CMD" update 2>/dev/null || echo "Mise à jour automatique non supportée ou déjà effectuée."
fi

# --- 4. Nettoyage et ACQUITTEMENT (Acknowledge) sécurisé des crashs GPU ---
echo "=== Nettoyage et acquittement des verrous graphiques ==="

# CORRECTION : On utilise la commande officielle interne de BedrockOnLinux.
# Cela supprime le fichier marqueur de crash GPU sans corrompre les dossiers de jeux de Wine.
if command -v "$APP_CMD" &> /dev/null; then
  "$APP_CMD" doctor --acknowledge-gpu-crash &>/dev/null
fi

# Nettoyage sécurisé uniquement des verrous d'instance de l'interface (sans toucher à Wine)
rm -f ~/.config/bedrock-on-linux/*.lock 2>/dev/null

# --- 5. Lancement du jeu ---
echo "=== Lancement du jeu ==="
if command -v "$APP_CMD" &> /dev/null; then
  # Premier essai standard
  "$APP_CMD" play
  EXIT_CODE=$?

  # Si échec, second essai avec contournement forcé du GPU
  if [ $EXIT_CODE -ne 0 ]; then
    echo "Échec du lancement standard (Code $EXIT_CODE). Nouvelle tentative avec bypass GPU..."
    export BOL_ALLOW_UNSAFE_GPU=1
    "$APP_CMD" play
  fi
else
  echo "Erreur : Impossible de lancer le jeu, exécutable introuvable."
  exit 1
fi
