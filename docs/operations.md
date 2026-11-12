# Données et exploitation

Les volumes nommés sont gérés par le moteur de chaque machine et préfixés par `homelab-<instance>`. Les données ne circulent pas via Git ou NetBird automatiquement. `down` arrête les services sans supprimer les volumes. Ne pas utiliser `down -v`, `docker volume prune` ou une réinitialisation Docker Desktop sans copie vérifiée des données.

Pour personnaliser le stockage, les bind mounts imports/backups/datasets/sorties sont déjà configurables. Les volumes applicatifs sont nommés par défaut afin de fonctionner aussi sur Docker Desktop. Pour les déplacer, utiliser les options de stockage du moteur ou remplacer volontairement leur montage par un bind absolu dans une variante Compose locale ignorée par Git (`compose.local.yaml` par exemple, à ajouter à `.gitignore`). Vérifier les UID, permissions et garanties de stockage avant migration.

## Sauvegarder et récupérer

- PostgreSQL : utiliser les commandes `backup` et tester `restore` dans une instance vide. Copier les exports vers un autre support ; les dumps locaux seuls ne protègent pas d'une panne de disque.
- Minecraft : arrêter proprement le serveur, sauvegarder l'intégralité du volume `/data`, redémarrer. Restaurer avec le même nom de projet et une version compatible.
- Next.js : le code et le verrou npm sont dans Git ; les fichiers téléversés par une future application nécessiteront un volume et une sauvegarde dédiés.
- Data Lab : sauvegarder le volume notebooks et les dossiers de sortie. Les datasets originaux restent dans imports et doivent avoir leur propre copie.
- Portainer/pgAdmin : sauvegarder leurs volumes (ou utiliser la sauvegarde intégrée Portainer selon la version), plus les configurations locales dans un coffre chiffré. Le secret agent et les accès ne sont pas récupérables depuis ce dépôt.

Pour une copie à froid d'un volume, arrêter sa stack et utiliser un outil de sauvegarde Docker de confiance pour archiver le volume ; vérifier le nom avec `docker volume inspect`. Restaurer les permissions, tester l'archive dans une instance distincte puis contrôler les données applicatives. Ne pas copier les fichiers d'un volume PostgreSQL en fonctionnement comme sauvegarde logique.

## Mises à jour et diagnostic

Sauvegarder, lire les notes de version, fixer le tag souhaité dans le fichier env, puis `config` et `update`. Les tags `lts`, `java21`, `17-bookworm`, `latest` et les images de base sont mobiles : noter les digests pour un retour reproductible. Un retour d'image n'annule pas une migration de données ; il peut exiger une restauration.

`logs` affiche les 100 dernières lignes puis suit le service. `docker compose ... ps` permet de voir son état. Un healthcheck en échec signale un problème ; il ne provoque pas automatiquement un redémarrage. Pour PostgreSQL, vérifier les droits de backups/imports, l'espace disque et les collisions de ports ; pour Next.js, le lockfile et le contexte de build ; pour NetBird, la disponibilité de l'IP de liaison ; pour un Pi, l'architecture de chaque image et module natif.

Les commandes de configuration utilisent `config --quiet` afin de ne pas afficher les mots de passe interpolés. Un `docker compose config` sans cette option, `inspect` ou un export Portainer peut révéler les secrets. Ne pas les joindre à un ticket public. Faire régulièrement un exercice de restauration, sans attendre une panne réelle.
