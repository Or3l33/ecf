#!/bin/bash
# Importe un modèle Zabbix (fichier YAML, XML ou JSON) via l'API, comme le bouton
# « Importer » de Collecte de données > Modèles.
# Usage : ZABBIX_TOKEN=<jeton API> ./importer-modele.sh <fichier> [url de l'API]
set -euo pipefail
fichier=$1
api=${2:-http://localhost/zabbix/api_jsonrpc.php}
format=${fichier##*.}; [ "$format" = yml ] && format=yaml

# Règles d'import : on crée ce qui manque et on met à jour ce qui existe déjà
regles='{
  "template_groups": {"createMissing": true, "updateExisting": true},
  "templates":       {"createMissing": true, "updateExisting": true},
  "items":           {"createMissing": true, "updateExisting": true},
  "triggers":        {"createMissing": true, "updateExisting": true},
  "graphs":          {"createMissing": true, "updateExisting": true},
  "discoveryRules":  {"createMissing": true, "updateExisting": true},
  "valueMaps":       {"createMissing": true, "updateExisting": true},
  "templateDashboards": {"createMissing": true, "updateExisting": true},
  "templateLinkage": {"createMissing": true}
}'

requete=$(jq -n --arg format "$format" --rawfile source "$fichier" --argjson rules "$regles" \
  '{jsonrpc: "2.0", method: "configuration.import", id: 1,
    params: {format: $format, source: $source, rules: $rules}}')

curl -s "$api" -H 'Content-Type: application/json-rpc' \
  -H "Authorization: Bearer $ZABBIX_TOKEN" -d "$requete"
echo
