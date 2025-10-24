#!/bin/bash
# =============================================================================
# Script : postinstall.sh
# Objectif : Sécurisation avancée d'Ubuntu en environnement de production
#
# Description :
#   Ce script automatise les principales opérations de durcissement d’un système
#   Ubuntu fraîchement installé. Il applique une politique de sécurité stricte
#   pour garantir la conformité et la robustesse d’un serveur en contexte
#   professionnel (production, SI critique, cloud privé…).
#
# Fonctionnalités principales :
#   - Mises à jour système et sécurité automatiques
#   - Suppression/désactivation des services non essentiels
#   - Renforcement des accès SSH et sudo
#   - Gestion stricte des utilisateurs/groupes
#   - Pare-feu (UFW/nftables), IDS/IPS (Fail2ban, AIDE…)
#   - Politiques de mots de passe fortes et gestion des droits
#   - Journalisation, audit et alertes
#   - Protection des ports/services, cloisonnement réseau
#   - Vérification continue de l’intégrité du système
#
# Compatibilité :
#   - Ubuntu >= 22.04 LTS (x86_64/arm64)
#   - Doit être lancé avec les privilèges root (sudo)
#
# Usage :
#   sudo ./postinstall.sh [options]
#   (options : --dry-run, --verbose, etc. à adapter si besoin)
#
# Idempotence :
#   - Chaque opération vérifie l’état préalable avant toute modification,
#     ce qui permet d’exécuter le script plusieurs fois sans risque de doublon
#     ou de corruption.
#
# Conditions/prérequis :
#   - Système Ubuntu propre, sans personnalisation préalable
#   - Connexion Internet requise pour l’installation des paquets
#
# Sécurité / Avertissements :
#   - Script à utiliser UNIQUEMENT sur une machine dédiée à la production.
#   - Des interruptions critiques (reboot, modification des accès) sont possibles.
#   - Sauvegarder toute donnée importante avant exécution.
#
# Logs et reporting :
#   - Toutes les opérations sont loguées dans /var/log/postinstall.log
#   - En cas d’erreur critique, le script s’arrête et affiche la cause.
#
# Auteur : By 1BoNoBo1 - 2025
# Licence : Usage interne / libre pour usage non commercial
# Historique :
#   - v1.0 [2025-08-06] : Version initiale
#
# Contact : [ton-email@domain.com]
# Convention de retour :
#   - 0 = succès ; 1 = erreur critique ; 2 = erreur mineure
# Emplacement recommandé :
#   - /usr/local/sbin/postinstall.sh
# =============================================================================
set -euo pipefail  # Stopper si erreur, variable non définie ou erreur de pipe
# Vérification des privilèges root
if [[ $EUID -ne 0 ]]; then
  echo "❌ Ce script doit être exécuté avec sudo/root." >&2
  exit 1
fi
# Chemin du log
LOG_FILE="/var/log/postinstall.log"
# Création du fichier de log s'il n'existe pas
if [[ ! -f "$LOG_FILE" ]]; then
  touch "$LOG_FILE"
  chmod 600 "$LOG_FILE"  # Permissions strictes
fi
# Fonction de log
log() {
  local message="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}
# Fonction de log d'erreur
log_error() {
  local message="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $message" | tee -a "$LOG_FILE" >&2
}
# Fonction de vérification de commande
check_command() {
  local cmd="$1"
  if ! command -v "$cmd" &> /dev/null; then
    log_error "La commande '$cmd' n'est pas installée. Veuillez l'installer avant de continuer."
    exit 1
  fi
}
# Vérification des commandes essentielles
check_command "apt"
check_command "ufw"
check_command "systemctl"
check_command "ssh"
check_command "fail2ban"
check_command "aide"
# Mise à jour du système
log "Mise à jour du système..."
apt update && apt upgrade -y
if [[ $? -ne 0 ]]; then
  log_error "Échec de la mise à jour du système."
  exit 1
fi