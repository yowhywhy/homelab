# Applications

## Minecraft Java

Image [itzg/minecraft-server](https://docker-minecraft-server.readthedocs.io/en/latest/), monde dans le volume `homelab-<instance>_world` par défaut. Configurer `MC_TYPE=VANILLA` ou `PAPER`, `MC_VERSION`, `MC_MEMORY`, `MC_MAX_PLAYERS` et `MC_PORT`. Accepter l'EULA avec `MC_EULA=TRUE` uniquement après lecture. Les valeurs par défaut sont **Minecraft 1.21.11, Java 21 et 12 Go de mémoire JVM** (`MC_MEMORY=12G`). Cette mémoire concerne la JVM, pas une limite de consommation totale du conteneur : prévoir de la RAM supplémentaire pour Java, Docker et le système. Ce réglage n'est pas adapté à un Pi disposant de moins de mémoire ; réduire `MC_MEMORY` sur cette machine.

`MC_ONLINE_MODE=FALSE` configure `online-mode=false` : les clients hors ligne peuvent se connecter sans vérification de leur compte Microsoft/Mojang. Avec cette [option de l'image](https://docker-minecraft-server.readthedocs.io/en/latest/configuration/server-properties/), les pseudos ne constituent plus une identité authentifiée : un joueur peut usurper celui d'un autre, y compris d'un opérateur. Réserver l'accès aux pairs NetBird de confiance. Pour rétablir l'authentification officielle, utiliser `MC_ONLINE_MODE=TRUE`. Passer du mode authentifié au mode hors ligne change les UUID des joueurs : inventaires, positions, statistiques et permissions peuvent nécessiter une migration ; conserver une sauvegarde des données avant ce changement.

`down` envoie un arrêt propre et laisse jusqu'à deux minutes au serveur pour sauvegarder. `up` le redémarre ; les plantages peuvent déclencher la politique de redémarrage. Ne pas tuer le conteneur pendant l'écriture du monde. Sauvegarder le volume serveur arrêté avant toute modification de version. Éviter les rétrogradations de mondes. RCON est désactivé ; aucun port d'administration RCON n'est publié. Utiliser les logs pour diagnostiquer une première génération de monde longue.

### Importer un serveur Java existant

Arrêter proprement l'ancien serveur, puis faire une copie complète de son dossier avant toute modification. Pour le premier démarrage, conserver son type et sa version si possible ; tester la mise à niveau vers 1.21.11 sur une copie. Ne jamais ouvrir un monde issu d'une version plus récente avec une version plus ancienne.

Récupérer en priorité :

| Fichiers / dossiers | Contenu |
| --- | --- |
| `world/` ou le dossier défini par `level-name` | Monde complet : `level.dat`, régions, dimensions, `playerdata`, statistiques, advancements et datapacks |
| `world_nether/`, `world_the_end/` et autres mondes éventuels | Dimensions et mondes séparés, notamment sous Bukkit/Paper ; garder leurs noms et leur structure |
| `server.properties` | Paramètres de jeu et nom du monde |
| `ops.json`, `whitelist.json`, `banned-players.json`, `banned-ips.json` | Opérateurs, liste blanche et bannissements ; vérifier les identités si le mode en ligne change |
| `plugins/`, `config/`, `bukkit.yml`, `spigot.yml`, `paper.yml` si présents | Plugins, données et configuration Paper/Bukkit ; seulement avec un serveur et des plugins compatibles |

Le plus simple est de copier **le contenu du dossier serveur complet** dans un dossier local dédié, puis de retirer de cette copie les anciens JAR serveur, scripts de lancement, bibliothèques/cache téléchargés et logs inutiles. L'image télécharge elle-même le serveur correspondant à `MC_TYPE` et `MC_VERSION`. Garder l'original intact. Un serveur Forge/Fabric/moddé nécessite une configuration spécifique : le défaut Vanilla ne suffit pas. Ne pas convertir Paper en Vanilla pendant l'import ; leurs dimensions peuvent être organisées différemment.

Exemple Windows : déposer les fichiers directement dans `C:/Dev/homelab/data/minecraft`, de sorte que `server.properties` soit dans ce dossier et le monde dans `C:/Dev/homelab/data/minecraft/world`, **sans dossier serveur supplémentaire imbriqué**. Puis modifier `config/minecraft.env` :

```dotenv
MC_DATA_PATH=C:/Dev/homelab/data/minecraft
MC_LEVEL=world
MC_TYPE=VANILLA
MC_VERSION=1.21.11
MC_MEMORY=12G
MC_ONLINE_MODE=FALSE
```

Adapter `MC_LEVEL` à l'ancien `level-name` et `MC_TYPE=PAPER` si l'ancien serveur utilisait Paper. Sous Linux, utiliser par exemple `MC_DATA_PATH=/home/votre-compte/homelab/data/minecraft` et donner au conteneur les droits de lecture/écriture sur ce dossier dédié. Le chemin doit être absolu sur la machine Docker cible. `data/` est ignoré par Git ; ne jamais committer ces données.

Les variables de l'image reprennent la priorité sur les propriétés qu'elles gèrent : vérifier dans le fichier env le port, le nombre de joueurs, le nom de monde et le mode en ligne, même après avoir copié `server.properties`. Le port interne reste 25565 ; `MC_PORT` règle le port publié sur l'hôte.

Une fois les fichiers copiés et l'EULA acceptée, exécuter volontairement :

```powershell
# Windows / PowerShell
.\scripts\homelab.ps1 down minecraft
.\scripts\homelab.ps1 config minecraft
.\scripts\homelab.ps1 up minecraft
.\scripts\homelab.ps1 logs minecraft
```

```bash
# Linux / Bash
bash scripts/homelab.sh down minecraft
bash scripts/homelab.sh config minecraft
bash scripts/homelab.sh up minecraft
bash scripts/homelab.sh logs minecraft
```

Arrêter également la nouvelle stack avant toute copie si elle utilise déjà le dossier cible. Ne pas mélanger un monde existant avec un monde généré lors d'un essai. Vérifier le chargement du bon monde, les dimensions, les inventaires et les plugins. Un `MC_DATA_PATH` renseigné remplace le montage du volume nommé : il ne copie pas ses données. L'ancien volume est conservé mais n'est plus monté ; pour le réutiliser, arrêter la stack, vider `MC_DATA_PATH` puis relancer avec le même nom d'instance.

## Next.js / React

`templates/nextjs` contient une page minimale et un Dockerfile avec étapes dépendances, développement, build et runtime non-root. Le runtime utilise la [sortie standalone](https://nextjs.org/docs/app/api-reference/config/next-config-js/output). Le verrou npm doit être versionné avec le modèle ; `npm ci` est utilisé au build.

```powershell
.\scripts\homelab.ps1 init web
.\scripts\homelab.ps1 config web
.\scripts\homelab.ps1 up web
# Développement avec montage du code et volumes node_modules/.next séparés :
.\scripts\homelab.ps1 up web -Dev
```

Pour votre application : cloner le dépôt Git sur l'hôte, ajouter le Dockerfile et `.dockerignore`, activer `output: 'standalone'`, fournir un `package-lock.json` et un dossier `public` (même vide), puis définir `WEB_CONTEXT` sur le chemin absolu du clone. Les dépendances `devDependencies` sont disponibles pour compiler, mais seules les dépendances tracées sont copiées dans le runtime. Pour un monorepo, adapter le contexte et le tracing standalone.

Après un `git pull --ff-only` revu dans le dépôt applicatif, lancer `update web`. Ce script reconstruit l'application ; il ne récupère pas Git lui-même. Si les dépendances changent en développement, mettre à jour le volume de dépendances avec `docker compose -p homelab-web --env-file config/web.env -f compose/web/compose.yaml -f compose/web/compose.dev.yaml run --rm web npm ci`, puis relancer. Ne pas supprimer tous les volumes pour rafraîchir seulement les dépendances.

`APP_MESSAGE` est lu côté serveur à l'exécution. Les variables publiques `NEXT_PUBLIC_*` sont intégrées au build : les déclarer explicitement comme arguments de build si votre application en a besoin, puis reconstruire. Ne jamais y placer de secret. La page de démonstration n'ouvre pas de connexion SQL. Pour votre application, installer le client PostgreSQL/ORM choisi, puis renseigner `DATABASE_URL=postgresql://utilisateur:motdepasse@IP_NETBIRD_HOTE:5432/base` (encoder les caractères spéciaux du mot de passe dans l'URL).

Les stacks ont des réseaux Compose distincts : `postgres` n'est pas résolu depuis web et `localhost` vise le conteneur web lui-même. Sur un même hôte, on peut ajouter volontairement un réseau externe commun aux deux stacks, avec un alias DB unique par instance, puis utiliser cet alias. Pour la V1, l'adresse NetBird et le port publié constituent la connexion documentée ; vérifier l'accessibilité depuis le conteneur et limiter les règles réseau. Appliquer les migrations de votre app séparément. Pour une mise en ligne publique ultérieure, prévoir TLS et un reverse proxy selon les [recommandations Next.js](https://nextjs.org/docs/app/guides/self-hosting).

Pour une application React/Vite pure, réutiliser l'organisation Compose mais adapter le Dockerfile (build statique puis serveur HTTP). Le Dockerfile fourni est spécifique à Next.js et son serveur Node.

## Data Lab optionnel

Python 3.12, pandas, DuckDB, PyArrow et JupyterLab ; image construite localement, sans dépendre d'une image notebook mono-architecture. Définir un token long, puis `init datalab`, éditer la configuration et `up datalab`. Ouvrir `http://127.0.0.1:8888` et saisir le token. Les notebooks persistent dans un volume, `/datasets` monte les imports en lecture seule et `/output` reçoit les fichiers produits.

Sur Linux, préparer le dossier de sortie avec des droits d'écriture pour UID 1000 **avant** de démarrer : `mkdir -p data/lab-output imports`, puis adapter les droits de ces dossiers dédiés à votre compte/conteneur. Les bind mounts créés par Docker peuvent appartenir à root. Ne pas changer récursivement les droits d'un disque partagé entier.

```python
import duckdb
con = duckdb.connect('/output/analyse.duckdb')
con.execute("SET memory_limit='1GB'")
con.execute("SET temp_directory='/output/tmp'")
con.execute("COPY (SELECT * FROM read_csv_auto('/datasets/source.csv')) TO '/output/source.parquet' (FORMAT PARQUET)")
con.sql("SELECT count(*) FROM read_parquet('/output/source.parquet')").show()
```

DuckDB peut traiter les fichiers sans charger tout le jeu de données dans pandas. Réserver assez de disque temporaire et régler la RAM en fonction de l'hôte. Un dump PostgreSQL n'est pas un CSV : le restaurer dans PostgreSQL puis exporter les tables, par exemple `COPY ... TO STDOUT WITH CSV HEADER` via un client adapté, avant analyse. Aucun dump SQL arbitraire n'est exécuté par le Lab.
