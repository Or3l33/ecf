# ECF - Bachelor Administrateur Système DevOps

Dépôt de travail pour l'ECF.

## Contenu

| Fichier | Description |
|---|---|
| `monitoring.sh` | Installe Netdata (serveur de monitoring) sur Debian 13 et vérifie que le service tourne et que le port 19999 répond |

## Utilisation

```bash
sudo bash monitoring.sh
```

Tableau de bord Netdata : `http://<IP-de-la-VM>:19999`
