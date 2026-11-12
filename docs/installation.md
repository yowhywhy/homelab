# Installation et réseau privé

## Tour Linux x86-64

1. Installer Git, [Docker Engine et Compose](https://docs.docker.com/engine/install/) selon la distribution, en suivant les instructions officielles.
2. Vérifier `docker version` et `docker compose version`. L'accès au socket Docker confère des privilèges équivalents à root ; limiter ses utilisateurs.
3. Cloner le dépôt sur un disque disposant de suffisamment d'espace. Installer NetBird sur l'hôte et inscrire manuellement cette machine.
4. Initialiser et configurer Portainer, puis les stacks voulues. Ne lancer qu'après relecture des fichiers env.

## Raspberry Pi

Utiliser un OS **64 bits** (Raspberry Pi OS 64 bits ou Ubuntu ARM64), puis Docker Engine et Compose compatibles aarch64. Vérifier `uname -m` : `aarch64`, pas `armv7l`. Un SSD est préférable à une carte SD pour PostgreSQL, Minecraft et les gros fichiers. Prévoir refroidissement, alimentation et RAM suffisants ; commencer avec une seule charge lourde.

Installer NetBird sur l'hôte, inscrire manuellement la machine, puis déployer `agent`. Docker rootful avec le chemin standard `/var/lib/docker/volumes` constitue la cible initiale ; pour un data-root personnalisé ou Docker rootless, adapter `DOCKER_VOLUMES_PATH`, le socket et les droits dans le Compose agent. Ces variantes ne sont pas validées.

## Portable Windows

Installer [Docker Desktop avec backend WSL2](https://docs.docker.com/desktop/setup/install/windows-install/) et utiliser les conteneurs Linux. Vérifier que le moteur fonctionne avant les commandes `up`. Cloner sous Windows pour PowerShell ou dans le filesystem de la distribution WSL pour Bash ; ne pas mélanger les chemins Windows et WSL dans le même fichier env.

Les volumes Docker nommés restent dans la VM Linux de Docker Desktop. Le chemin hôte Windows n'est pas `/var/lib/docker/volumes`. Le montage de l'agent vise le filesystem du moteur Linux ; sa disponibilité dépend de Docker Desktop. Tester la gestion des volumes via Portainer avant d'en dépendre. La V1 ne gère pas les conteneurs Windows natifs.

Les chemins bind absolus Windows doivent utiliser `/`, par exemple `D:/Homelab/imports`. Autoriser leur partage dans Docker Desktop si nécessaire. Sous WSL, préférer `/home/...` aux montages `/mnt/c/...` pour les builds et la surveillance de fichiers. La RAM configurée dans Docker Desktop/WSL est partagée entre toutes les stacks.

## NetBird sur les hôtes

Suivre [l'installation officielle](https://docs.netbird.io/get-started/install) pour chaque OS. L'inscription, le choix du compte et l'approbation des pairs restent manuels. Aucun token d'inscription n'est stocké ici.

1. Nommer les pairs (tour, pi, portable) et relever leurs adresses NetBird.
2. Créer des groupes dédiés et des règles autorisant la tour vers les agents TCP 9001. Restreindre les interfaces d'administration à vos machines administratrices. Examiner et retirer la règle globale permissive si votre compte en possède une, après avoir ajouté les règles nécessaires.
3. Sous Linux, définir `BIND_IP` sur l'adresse NetBird du pair concerné, puis démarrer la stack après que cette adresse soit disponible. Si NetBird est indisponible, un démarrage peut échouer ; rétablir le réseau puis relancer `up`.
4. Tester depuis la tour `Test-NetConnection <IP-NETBIRD-AGENT> -Port 9001` sous PowerShell, ou `nc -vz <IP-NETBIRD-AGENT> 9001` sous Linux si netcat est installé.

Sous Docker Desktop, une adresse VPN Windows peut ne pas être utilisable comme adresse de publication par le moteur de la VM. Commencer avec loopback pour les usages locaux. Si l'accès distant exige `BIND_IP=0.0.0.0`, configurer d'abord le pare-feu Windows pour n'autoriser que les pairs NetBird voulus sur ce port, puis vérifier depuis le LAN que l'accès est refusé. Ne pas considérer les ACL NetBird comme une protection des autres interfaces. Garder le portable local si cette restriction ne peut pas être garantie.

Les ports publiés par Docker Linux peuvent contourner UFW : utiliser une liaison IP explicite et, si nécessaire, les règles de filtrage adaptées au backend Docker. Ne pas ouvrir 9001 ou l'API Docker 2375 sur Internet. Les [ports réseau NetBird](https://docs.netbird.io/about-netbird/ports-and-firewalls) concernent le tunnel, en plus des règles applicatives choisies ici.

## Architectures et images

| Composant | Cibles prévues | Limites à vérifier |
| --- | --- | --- |
| Portainer CE et Agent | Linux amd64 / arm64 | tags identiques serveur/agents ; vérifier les manifests du tag |
| Minecraft `java21` | amd64 / arm64 | Java à adapter à la version Minecraft ; plugins Paper parfois natifs |
| PostgreSQL `17-bookworm` | amd64 / arm64 | extensions externes non fournies |
| pgAdmin | amd64 / arm64 selon tag | optionnel : si le tag choisi manque, utiliser un client SQL local |
| Next.js / Node 24 slim | amd64 / arm64 | modules natifs de votre app à vérifier |
| Data Lab / Python slim | amd64 / arm64 | disponibilité des wheels pip pour chaque version |

Avant déploiement sur une nouvelle architecture, exécuter par exemple `docker buildx imagetools inspect itzg/minecraft-server:java21` et répéter pour les tags choisis. La [matrice Java de l'image Minecraft](https://docker-minecraft-server.readthedocs.io/en/latest/versions/java/) détaille les architectures par tag. Aucun `platform: linux/amd64` n'est forcé ; aucune émulation n'est imposée. Les builds, pulls et tests ARM64 restent à effectuer sur les machines cibles.
