# PostgreSQL

## Instances et accès

Le volume `homelab-<instance>_database` isole chaque instance. Créer par exemple `postgres-test` avec `init postgres -Instance postgres-test` (Bash : `--instance postgres-test`), changer son port à 5433 et l'administrer avec ce même nom. Pour pgAdmin, utiliser `up postgres -Admin` et définir au préalable `PGADMIN_PASSWORD` ainsi qu'un email valide. Dans pgAdmin, enregistrer le serveur avec hôte **postgres**, port **5432**, utilisateur/base/mot de passe du fichier env. Depuis l'hôte, utiliser `127.0.0.1:PG_PORT` ou l'adresse NetBird configurée.

Les variables `POSTGRES_*` initialisent uniquement un volume vide. Modifier le fichier env ne change pas un mot de passe existant : utiliser une commande SQL `ALTER ROLE` dans une session d'administration, puis aligner la configuration. Le volume pgAdmin contient ses propres comptes et paramètres ; les variables d'initialisation ne les réinitialisent pas non plus.

## Exporter

```powershell
.\scripts\homelab.ps1 backup postgres
.\scripts\homelab.ps1 backup postgres -File avant-migration.dump
.\scripts\homelab.ps1 backup postgres -File export.sql
.\scripts\homelab.ps1 backup postgres -Instance postgres-test -File test.dump
```

```bash
bash scripts/homelab.sh backup postgres --file avant-migration.dump
```

Les exports sont écrits directement dans `/backups`, donc dans `BACKUPS_PATH` sur l'hôte. Aucun flux binaire ne traverse une redirection PowerShell. `.dump` et `.backup` utilisent le format custom ; `.sql` produit du SQL texte. Le fichier final n'est publié qu'après succès de `pg_dump`, et un fichier existant n'est pas écrasé. La sauvegarde capture une base cohérente pendant son fonctionnement, mais pas les rôles globaux, les autres bases ni les fichiers applicatifs. Sauvegarder les rôles séparément avec `pg_dumpall --globals-only` si nécessaire et traiter ce fichier comme sensible.

## Importer SQL ou custom

1. Placer le fichier dans `IMPORTS_PATH` (par défaut `imports/` à la racine). Les fichiers restent hors Git et hors image Docker.
2. Choisir une base **vide**, de préférence une nouvelle instance avec un port distinct. Sauvegarder la base cible avant tout import. Un dump SQL peut modifier ou détruire des données : n'importer que des sources de confiance.
3. Appeler la restauration avec un nom simple, sans chemin :

```powershell
.\scripts\homelab.ps1 restore postgres -Instance postgres-test -File source.dump
.\scripts\homelab.ps1 restore postgres -Instance postgres-test -File source.sql
```

```bash
bash scripts/homelab.sh restore postgres --instance postgres-test --file source.dump
```

Les scripts utilisent `psql -X -v ON_ERROR_STOP=1 --single-transaction` pour SQL et `pg_restore --exit-on-error --single-transaction --no-owner --no-acl` pour custom. Ils n'ajoutent pas `--clean` et remontent les erreurs. Un dump SQL doit viser une seule base et ne pas inclure `CREATE DATABASE`, `\connect`, `VACUUM` ou une autre commande incompatible avec une transaction. Les fichiers compressés `.sql.gz`, archives au format directory et dumps globaux ne sont pas gérés par cette commande : préparer un dump compatible ou utiliser les outils PostgreSQL manuellement.

Les archives custom doivent être produites avec un `pg_dump` compatible avec le `pg_restore` de la cible ; les outils d'une version ancienne ne lisent pas nécessairement un dump plus récent. Le SQL peut référencer des propriétaires/extensions absents : les préparer ou exporter sans ces dépendances. Pour réimporter un export local, copier le fichier de `backups/` vers `imports/`. Les imports sont montés en lecture seule.

## Gros volumes, mémoire et stockage

Utiliser un SSD local avec assez d'espace pour la base, les index, le WAL, les dumps et les fichiers temporaires. Les imports restent montés depuis l'hôte : aucune copie dans la couche du conteneur. Préparer les dossiers sous Linux et autoriser l'UID PostgreSQL de l'image choisie à écrire dans `BACKUPS_PATH` ; vérifier cet UID pour le tag utilisé plutôt que supposer qu'il reste identique. Les sauvegardes seront créées par le processus PostgreSQL du conteneur.

`PG_SHARED_BUFFERS=128MB`, `PG_WORK_MEM=4MB`, `PG_MAINTENANCE_WORK_MEM=64MB`, `PG_MAX_CONNECTIONS=50` sont des valeurs de départ prudentes. `work_mem` s'applique à chaque opération de tri/hash et peut se multiplier par connexion. Ajuster selon la RAM réellement disponible ; laisser de la mémoire au système et aux autres stacks. `PG_SHM_SIZE=256m` règle `/dev/shm`, pas une limite RAM totale ; augmenter si des requêtes parallèles épuisent cet espace. Des limites de ressources peuvent être ajoutées après mesure.

Pour de très gros imports, une transaction unique peut consommer beaucoup de WAL et de disque ; utiliser une restauration manuelle adaptée avec surveillance et sauvegarde préalable si elle n'est pas viable. `pg_restore --jobs` est possible pour le format custom mais incompatible avec la transaction unique de la commande fournie. Exécuter `ANALYZE` après import et vérifier comptes de lignes et contraintes.

Ne jamais passer directement de PostgreSQL 17 à une autre version majeure avec le même volume. Préparer une nouvelle instance, exporter/importer ou utiliser une procédure `pg_upgrade` adaptée. Le chemin de données fourni cible PostgreSQL 17 ; les images majeures suivantes peuvent changer d'organisation. Voir l'[image officielle PostgreSQL](https://hub.docker.com/_/postgres) et la [documentation de sauvegarde](https://www.postgresql.org/docs/17/backup.html).
