#!/usr/bin/env zsh
# --------------------------------------------------
# Pare‑feu UFW
# --------------------------------------------------

# ---------- activer_ufw ----------
unalias activer_ufw 2>/dev/null
activer_ufw() {
  sudo ufw enable
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow ssh
  echo_color "🛡️  UFW activé (+SSH permis)." $VERT
}

# ---------- desactiver_ufw ----------
unalias desactiver_ufw 2>/dev/null
desactiver_ufw() {
  sudo ufw disable
  echo_color "🚫 UFW désactivé." $ROUGE
}

# ---------- status_ufw ----------
unalias status_ufw 2>/dev/null
status_ufw() {
  sudo ufw status verbose
}

# ---------- bloquer_tout ----------
unalias bloquer_tout 2>/dev/null
bloquer_tout() {
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  echo_color "🌐 Règles par défaut mises à jour." $CYAN
}
