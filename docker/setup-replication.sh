#!/bin/bash
# Met en place la réplication MySQL : mon-mysql (source) -> mon-mysql-replica (réplique).
# À lancer depuis le dossier docker/ après "docker compose up -d --wait".
# Relançable sans risque : si la réplique tourne déjà, seul l'état est affiché.
set -euo pipefail

cd "$(dirname "$0")"
set -a; . ./.env; set +a

SOURCE=mon-mysql
REPLICA=mon-mysql-replica

# Exécute du SQL (lu sur l'entrée standard) dans un conteneur, en root
sql() { docker exec -i -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" "$1" mysql -uroot -N; }

# 1. Utilisateur de réplication sur la source (droit REPLICATION SLAVE uniquement)
sql "$SOURCE" <<EOF
CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED BY '$REPL_PASSWORD';
ALTER USER 'repl'@'%' IDENTIFIED BY '$REPL_PASSWORD';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
EOF

if [ -z "$(echo "SHOW REPLICA STATUS;" | sql "$REPLICA")" ]; then
    # 2. Copie initiale : dump de la base de l'application avec la position GTID de la source
    echo "SET GLOBAL super_read_only = OFF; RESET BINARY LOGS AND GTIDS;" | sql "$REPLICA"
    docker exec -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" "$SOURCE" \
        mysqldump -uroot --databases "$DB_NAME" --single-transaction \
        --routines --triggers --events --set-gtid-purged=ON 2>/dev/null \
        | sql "$REPLICA"

    # 3. Branchement sur la source : SOURCE_AUTO_POSITION reprend juste après le dump grâce aux GTID
    sql "$REPLICA" <<EOF
CHANGE REPLICATION SOURCE TO
    SOURCE_HOST = 'db',
    SOURCE_USER = 'repl',
    SOURCE_PASSWORD = '$REPL_PASSWORD',
    SOURCE_AUTO_POSITION = 1,
    SOURCE_SSL = 1;
START REPLICA;
EOF
fi

# 4. Lecture seule stricte sur la réplique, conservée après redémarrage
echo "SET PERSIST super_read_only = ON;" | sql "$REPLICA"

sleep 2
docker exec -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" "$REPLICA" mysql -uroot -e "SHOW REPLICA STATUS\G" \
    | grep -E 'Replica_(IO|SQL)_Running:|Seconds_Behind_Source|Last_(IO|SQL)_Error:'
