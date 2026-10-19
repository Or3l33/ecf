# ECF - Bachelor Administrateur Système DevOps

Dépôt de travail pour l'ECF.

## Contenu

| Fichier | Description |
|---|---|
| `monitoring.sh` | Installe Netdata (serveur de monitoring) sur Debian 13 et vérifie que le service tourne et que le port 19999 répond |
| `docker/app/Dockerfile` | Image `mon-env-php` : Apache, PHP 8.2, extensions `pdo_mysql`, `mysqli`, `gd`, `zip`, Composer 2 et client MySQL |
| `docker/app/src/index.php` | Page de test : version de l'application, extensions PHP, connexion MySQL et compteur de visites (v2) |
| `docker/docker-compose.yml` | Application + MySQL 8.4 sur le réseau `mon-reseau-app`, limites CPU, mémoire et stockage |
| `docker/.env.example` | Modèle du fichier `.env` (mots de passe, version de l'application) |

## Monitoring

```bash
sudo bash monitoring.sh
```

Tableau de bord Netdata : `http://<IP-de-la-VM>:19999`

## Docker

### Lancement

```bash
cd docker
cp .env.example .env               # puis remplacer les mots de passe
chmod 600 .env
docker network create mon-reseau-app
docker compose up -d --build --wait
curl http://localhost:8080/
```

### Mise à jour de l'application

```bash
# après modification de app/src/, changer APP_VERSION dans .env (ex. v2 -> v3)
docker compose build app
docker compose up -d --no-deps app   # remplace uniquement le conteneur de l'application
```

Retour arrière : remettre l'ancienne valeur de `APP_VERSION` dans `.env` puis relancer `docker compose up -d --no-deps app`. Les données MySQL sont dans le volume `db-data` et ne sont pas touchées.

### Limites de ressources du conteneur `app`

| Ressource | Limite |
|---|---|
| CPU | 2 |
| Mémoire | 510 Mo |
| Stockage | système de fichiers en lecture seule, seuls `/tmp` (50 Mo), `/var/run/apache2` (10 Mo) et `/var/lock/apache2` (4 Mo) sont inscriptibles |

`storage_opt: size=` n'est pas utilisé : sur ext4 avec overlayfs, Docker l'accepte mais ne l'applique pas.

```bash
docker inspect mon-conteneur-app --format '{{.HostConfig.NanoCpus}} {{.HostConfig.Memory}} {{.HostConfig.ReadonlyRootfs}} {{.HostConfig.Tmpfs}}'
```
