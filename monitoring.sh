#!/usr/bin/env bash
# monitoring.sh - Installe Netdata (serveur de monitoring) sur Debian 13
# Usage : sudo bash monitoring.sh

set -euo pipefail

PORT=19999
KICKSTART_URL="https://get.netdata.cloud/kickstart.sh"
KICKSTART_FILE="$(mktemp /tmp/netdata-kickstart.XXXXXX.sh)"

# 1. Le script doit être lancé en root (installation de paquets, services)
if [[ $EUID -ne 0 ]]; then
    echo "Erreur : lancez ce script avec sudo : sudo bash $0" >&2
    exit 1
fi

# 2. Installation des outils nécessaires au téléchargement
echo "==> Installation des prérequis"
apt-get update -q
apt-get install -y -q curl ca-certificates

# 3. Installation de Netdata (ignorée s'il est déjà présent)
if systemctl list-unit-files netdata.service >/dev/null 2>&1 \
   && systemctl list-unit-files netdata.service | grep -q netdata; then
    echo "==> Netdata est déjà installé"
else
    echo "==> Téléchargement de l'installeur officiel Netdata"
    curl -fsSL "$KICKSTART_URL" -o "$KICKSTART_FILE"

    echo "==> Installation de Netdata (version stable, sans télémétrie)"
    sh "$KICKSTART_FILE" --stable-channel --disable-telemetry --non-interactive
    rm -f "$KICKSTART_FILE"
fi

# 4. Activation au démarrage et lancement du service
echo "==> Activation et démarrage du service netdata"
systemctl enable --now netdata

# 5. Vérifications
echo "==> Vérification du service"
sleep 5
if systemctl is-active --quiet netdata; then
    echo "OK : le service netdata est actif"
else
    echo "ERREUR : le service netdata n'est pas actif" >&2
    systemctl status netdata --no-pager >&2 || true
    exit 1
fi

echo "==> Vérification du port $PORT"
if ss -tln | grep -q ":$PORT "; then
    echo "OK : Netdata écoute sur le port $PORT"
else
    echo "ERREUR : rien n'écoute sur le port $PORT" >&2
    exit 1
fi

HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:$PORT/api/v1/info")
if [[ "$HTTP_CODE" == "200" ]]; then
    echo "OK : l'API Netdata répond (HTTP $HTTP_CODE)"
else
    echo "ERREUR : l'API Netdata répond HTTP $HTTP_CODE" >&2
    exit 1
fi

IP=$(hostname -I | awk '{print $1}')
echo
echo "Netdata est installé. Tableau de bord : http://$IP:$PORT"
