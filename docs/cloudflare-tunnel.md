# Cloudflare Tunnel : services web et domaines

Cette stack expose volontairement des applications HTTP/HTTPS via Cloudflare. NetBird reste le réseau privé pour SSH, les agents Portainer, PostgreSQL et les autres accès d'administration. Aucune stack privée n'est automatiquement attachée au tunnel.

Trajet d'une requête : navigateur → HTTPS Cloudflare → tunnel sortant → `cloudflared` → `http://portfolio:3000` sur le réseau Docker `homelab-proxy`. Le HTTPS public est terminé chez Cloudflare ; l'exemple utilise HTTP entre conteneurs du même hôte. Aucun port entrant ni socket Docker n'est monté dans `cloudflared`, et aucun transfert de port sur la box n'est nécessaire.

## Créer le tunnel et préparer le domaine

1. Ajouter votre domaine à Cloudflare et terminer sa configuration DNS (nameservers Cloudflare pour le cas standard).
2. Depuis le dashboard Cloudflare / Cloudflare One, ouvrir la gestion des Tunnels dans la rubrique réseau, créer un tunnel de type **Cloudflared** et lui donner un nom, par exemple `homelab-tour`. Les intitulés des menus peuvent varier ; suivre le [guide officiel](https://developers.cloudflare.com/tunnel/get-started/).
3. Choisir Docker dans les instructions d'installation du connecteur. Copier uniquement la valeur du token présent après `--token`, sans lancer la commande proposée : le connecteur sera géré par Compose ou Portainer.
4. Préparer `config/cloudflare-tunnel.env` avec ce token. Ce fichier est ignoré par Git. Le token autorise le lancement d'un connecteur : ne pas le partager, l'inclure dans un screenshot ou le placer dans le Compose. En cas de fuite, le renouveler dans Cloudflare puis recréer le conteneur avec la nouvelle valeur.

Le routage est géré à distance : aucun `config.yml`, certificat d'inscription ou fichier de credentials n'est nécessaire ici. Le token est passé via `TUNNEL_TOKEN`, pris en charge par les [paramètres cloudflared](https://developers.cloudflare.com/tunnel/reference/run-parameters/). Il reste visible aux administrateurs du moteur Docker/Portainer ; éviter les exports de configuration contenant les secrets.

## Préparer Compose, sans démarrer

Depuis la racine du dépôt :

```powershell
# Windows / PowerShell
.\scripts\homelab.ps1 init cloudflare-tunnel
notepad config\cloudflare-tunnel.env
.\scripts\homelab.ps1 config cloudflare-tunnel
```

```bash
# Linux / Raspberry Pi / Bash
bash scripts/homelab.sh init cloudflare-tunnel
nano config/cloudflare-tunnel.env
bash scripts/homelab.sh config cloudflare-tunnel
```

`init all` inclut également cette stack et conserve les fichiers existants. Un token vide bloque la validation. `CLOUDFLARED_TAG=latest` suit l'image officielle ; fixer une version ou un digest vérifié pour figer le déploiement. Le même Compose vise Linux AMD64 et ARM64 sans forcer de plateforme. Vérifier le tag choisi avant déploiement avec `docker buildx imagetools inspect cloudflare/cloudflared:latest` ; les essais sur les deux architectures restent à effectuer.

## Exemple complet avec Next.js

Quand vous décidez de déployer, créer **une fois sur le moteur cible** le réseau bridge partagé :

```bash
docker network create homelab-proxy
```

Si ce réseau existe déjà, le réutiliser après vérification avec `docker network inspect homelab-proxy`. Le réseau est externe : ni le tunnel ni l'application ne le suppriment avec `down`, et il doit exister avant `up`. Ces commandes ne sont pas exécutées automatiquement par les scripts.

Initialiser `web` si son fichier env n'existe pas encore. Dans `config/web.env`, définir `WEB_PROXY_ALIAS=portfolio` (c'est aussi le défaut). Puis lancer volontairement :

```powershell
.\scripts\homelab.ps1 config web -Proxy
.\scripts\homelab.ps1 up web -Proxy
.\scripts\homelab.ps1 up cloudflare-tunnel
.\scripts\homelab.ps1 logs cloudflare-tunnel
```

```bash
bash scripts/homelab.sh config web --proxy
bash scripts/homelab.sh up web --proxy
bash scripts/homelab.sh up cloudflare-tunnel
bash scripts/homelab.sh logs cloudflare-tunnel
```

L'option Proxy ajoute uniquement `compose/web/compose.proxy.yaml` au Compose de production. Elle conserve le réseau privé de la stack et le port local existant (loopback par défaut). Conserver `BIND_IP=127.0.0.1` pour éviter un accès LAN qui contournerait Cloudflare Access. Utiliser aussi `-Proxy` / `--proxy` pour les futures commandes de déploiement et de mise à jour de cette variante ; un `up web` sans cette option retire l'attachement proxy. Ne pas exposer le serveur de développement Next.js publiquement.

Dans le dashboard du tunnel, ajouter une **Published application route** (anciennement Public hostname) :

| Champ | Valeur d'exemple |
| --- | --- |
| Sous-domaine | `portfolio` |
| Domaine | votre domaine, par exemple `example.com` |
| Chemin | vide, pour toute l'application |
| Type du service | HTTP |
| URL du service | `portfolio:3000` |

L'origine complète est `http://portfolio:3000`, pas `localhost:3000` : localhost désigne le conteneur cloudflared. Utiliser le port **interne** de l'application, pas le port publié sur l'hôte.

Le dashboard crée normalement le DNS correspondant lors de l'ajout de cette route. Vérifier qu'il existe, en mode proxifié, sans entrée A/AAAA/CNAME conflictuelle pour ce nom. Si une configuration manuelle est nécessaire, créer un CNAME `portfolio` vers `<UUID-DU-TUNNEL>.cfargotunnel.com` dans la zone du même compte et conserver également la route du tunnel. Un DNS seul ne définit pas l'origine HTTP. Ouvrir ensuite `https://portfolio.example.com` avec votre vrai domaine et vérifier le certificat, la page et les logs. Aucun enregistrement ne doit pointer vers l'IP résidentielle.

## Ajouter une application existante

Ajouter durablement le réseau externe dans son Compose, avec un alias unique :

```yaml
services:
  application:
    # Garder l'image, les volumes et les autres paramètres existants.
    networks:
      default:
      proxy:
        aliases:
          - mon-application
networks:
  proxy:
    external: true
    name: homelab-proxy
```

Conserver aussi les autres réseaux déjà utilisés par cette application, notamment pour sa base. Recréer la stack pour appliquer le réseau, puis ajouter une route `app.example.com` → `http://mon-application:PORT_INTERNE`. L'application doit écouter sur `0.0.0.0` dans le conteneur. Aucun `ports:` n'est nécessaire pour le tunnel. Un alias différent est indispensable pour chaque application/instance ; ne pas router vers le nom générique `web` si plusieurs stacks l'utilisent. Les conteneurs du réseau partagé peuvent communiquer entre eux : y placer uniquement les frontends choisis, pas leurs bases de données.

Un réseau bridge Docker est **local à un moteur**. Un tunnel sur la tour ne résout pas les alias du Pi. Déployer un tunnel distinct sur chaque hôte avec ses propres routes et token si les applications y diffèrent. Ne pas lancer le même tunnel sur tour et Pi avec des origines différentes : ses réplicas peuvent recevoir les mêmes requêtes. Un accès inter-hôtes par IP NetBird est une autre architecture et nécessite un routage explicite depuis le conteneur ; il n'est pas automatisé ici.

## Portainer

1. Sélectionner le moteur de la tour ou du Pi dans Portainer. Dans Networks, créer un réseau **bridge** nommé exactement `homelab-proxy` s'il est absent.
2. Créer une stack depuis ce dépôt Git, chemin `compose/cloudflare-tunnel/compose.yaml`.
3. Définir `TUNNEL_TOKEN` dans les variables de la stack Portainer, ainsi que `CLOUDFLARED_TAG` si souhaité. Les fichiers `config/` de votre poste ne sont pas envoyés à l'agent.
4. Déployer la stack quand vous êtes prêt. Aucun contexte de build ou bind mount n'est requis : le même fichier fonctionne sur un moteur distant via Agent.
5. Pour Next.js, utiliser `templates/portainer/web-proxy.compose.yaml`, fournir `WEB_IMAGE` avec une image production publiée compatible avec la cible, et choisir `WEB_PROXY_ALIAS=portfolio`. Ce modèle ne publie aucun port hôte. Pour construire/publier l'image, suivre le [guide Portainer](portainer.md).

Administrer ensuite logs, mise à jour et arrêt depuis Portainer. Choisir une autorité de déploiement par stack pour éviter les modifications contradictoires entre terminal et interface.

## Cloudflare Access facultatif

Un tunnel et un domaine ne créent **pas** d'authentification. Pour une interface privée exposée via le navigateur, créer une application **Self-hosted** dans Cloudflare Access pour son hostname, puis une politique Allow limitée à vos utilisateurs ou à votre fournisseur d'identité. Préparer cette protection avant de publier une interface sensible, et tester avec un navigateur privé qu'un utilisateur non autorisé est refusé. Voir la [procédure Access officielle](https://developers.cloudflare.com/cloudflare-one/access-controls/applications/http-apps/self-hosted-public-app/).

Les clients automatisés peuvent nécessiter des service tokens Access et une politique dédiée. Une route DNS/HTTP et une politique Access sont deux configurations distinctes. Access protège le chemin Cloudflare ; un port publié ouvert sur le LAN ou Internet offre un autre chemin. Pour Portainer, pgAdmin et Jupyter, NetBird reste le choix privé prévu par défaut ; aucune de ces stacks n'est modifiée ici.

## Diagnostic et maintenance

Autoriser les connexions sortantes nécessaires, notamment 7844 UDP (QUIC) ou TCP (HTTP/2), et DNS selon votre réseau. Voir les [règles de pare-feu Cloudflare](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/configure-tunnels/tunnel-with-firewall/). Il n'y a aucun port entrant à ouvrir.

- Tunnel déconnecté / erreur 1033 : vérifier token, logs et connectivité sortante.
- Erreur 502 : vérifier que l'application tourne, que les deux conteneurs sont sur `homelab-proxy`, que l'alias et le port interne sont corrects.
- Mauvaise application : rechercher des alias dupliqués ou plusieurs connecteurs du même tunnel avec des origines différentes.
- Application toujours accessible sans Access : vérifier le hostname protégé, les politiques et les ports directs.

`update cloudflare-tunnel` tire l'image puis recrée le connecteur ; le routage reste dans Cloudflare. L'auto-update interne est désactivée pour laisser Docker/Portainer gérer l'image. `down cloudflare-tunnel` coupe l'accès via ce connecteur mais ne supprime ni les DNS ni la configuration distante. Aucun volume persistant local n'est nécessaire au tunnel géré à distance.
