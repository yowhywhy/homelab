# Applications

## Minecraft Java

Image [itzg/minecraft-server](https://docker-minecraft-server.readthedocs.io/en/latest/), monde dans le volume `homelab-<instance>_world`. Configurer `MC_TYPE=VANILLA` ou `PAPER`, `MC_VERSION`, `MC_MEMORY`, `MC_MAX_PLAYERS` et `MC_PORT`. Accepter l'EULA avec `MC_EULA=TRUE` uniquement après lecture. Le défaut 1.21.1 utilise Java 21 ; changer `MC_IMAGE_TAG` si la version visée exige un autre Java. Allouer de la mémoire à l'hôte en plus du heap JVM (par exemple 2 Go JVM ne signifie pas 2 Go consommés au total).

`down` envoie un arrêt propre et laisse jusqu'à deux minutes au serveur pour sauvegarder. `up` le redémarre ; les plantages peuvent déclencher la politique de redémarrage. Ne pas tuer le conteneur pendant l'écriture du monde. Sauvegarder le volume serveur arrêté avant toute modification de version. Éviter les rétrogradations de mondes. RCON est désactivé ; aucun port d'administration RCON n'est publié. Utiliser les logs pour diagnostiquer une première génération de monde longue.

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
