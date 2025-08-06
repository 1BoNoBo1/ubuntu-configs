#!/bin/bash
# ================================================
# Script : installation_python.sh
# Installe Python 3, pip, git, build-essential, crée un venv et installe des paquets utiles.
# Usage : sudo ./installation_python.sh
# Compatibilité : Ubuntu ≥ 24.04 / Debian ≥ 12
# Auteur : Jean BoNoBo - 2025
# ================================================

set -e  # Stopper si erreur

if [[ $EUID -ne 0 ]]; then
  echo "❌ Ce script doit être exécuté avec sudo/root." >&2
  exit 1
fi

# Installation des paquets système nécessaires
apt update
apt install -y python3 python3-pip python3-venv git build-essential

echo "✅ Python 3, pip, venv, git et build-essential installés."

# Revenir à l'utilisateur appelant pour la suite (création venv, pipx, etc.)
# Détecte l'utilisateur original (pas root)
if [[ -n "$SUDO_USER" && "$SUDO_USER" != "root" ]]; then
  USER_HOME=$(eval echo "~$SUDO_USER")
else
  USER_HOME="$HOME"
fi

# Demande de création du venv
read -p "Souhaitez-vous créer un environnement virtuel Python dans le répertoire courant ? (o/n) " reponse
if [[ "$reponse" =~ ^[Oo]$ ]]; then
  if [[ ! -d ".venv" ]]; then
    echo "🔧 Création du venv..."
    sudo -u "$SUDO_USER" python3 -m venv .venv
    echo "✅ venv créé."
  else
    echo "⚠️ Un venv existe déjà ici."
  fi

  # Instructions pour activer le venv (le script ne peut pas activer le venv pour le shell appelant)
  echo "Pour activer le venv, exécute :"
  echo "source .venv/bin/activate"
  echo "Après activation, tu peux installer tes paquets avec pip."

  # Installe les paquets utiles dans le venv
  echo "🔧 Installation de paquets utiles dans le venv..."
  sudo -u "$SUDO_USER" bash -c "source .venv/bin/activate && pip install --upgrade pip && pip install requests beautifulsoup4 lxml"
  echo "✅ Paquets utiles installés dans le venv."
else
  echo "ℹ️ Aucun venv créé. Installation globale seulement."
fi

# Installer pipx globalement (dans le user, jamais en root)
echo "🔧 Installation de pipx pour l'utilisateur $SUDO_USER..."
sudo -u "$SUDO_USER" python3 -m pip install --user --upgrade pipx
echo "✅ pipx installé pour $SUDO_USER."

# Vérifie et ajoute ~/.local/bin au PATH si besoin (pour l'utilisateur)
if ! sudo -u "$SUDO_USER" bash -c 'echo $PATH' | grep -q "$USER_HOME/.local/bin"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$USER_HOME/.bashrc"
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$USER_HOME/.zshrc"
  echo "✅ $USER_HOME/.local/bin ajouté au PATH pour bash et zsh."
fi

# Instructions pipx
echo "Pour utiliser pipx, ouvre un nouveau terminal ou source ton .bashrc/.zshrc si nécessaire."
echo "Pour installer une app : pipx install nom_du_paquet"

echo "🎉 Installation terminée."