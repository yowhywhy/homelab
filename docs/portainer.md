# Portainer et déploiements depuis Git

## Serveur et agents

Sur la tour, initialiser `portainer`, fixer `PORTAINER_TAG`, `BIND_IP`, un secret commun long, puis lancer la stack. Ouvrir HTTPS 9443, vérifier le certificat autosigné attendu et créer immédiatement le compte administrateur. Si l'initialisation expire, redémarrer le conteneur via Compose et recommencer. Le socket Docker permet à Portainer d'administrer l'hôte avec des privilèges élevés.

Sur chaque machine secondaire, initialiser `agent`, définir **le même tag** que le serveur et **le même `AGENT_SECRET`**, puis publier 9001 sur le réseau privé selon le guide d'installation. Dans Portainer : Environments → Add environment → Docker Standalone → Agent ; saisir `IP_NETBIRD:9001`. Ne pas ajouter `https://` dans ce champ. Voir la [procédure officielle](https://docs.portainer.io/admin/environments/add/docker/agent).

Ne pas exposer le socket Docker via TCP non chiffré. Le secret agent complète les restrictions réseau ; il ne les remplace pas. Son changement doit être coordonné sur serveur et agents. Un portable éteint reste indisponible : Portainer ne déplace pas ses services vers une autre machine.

## Stacks Git réutilisables

Après publication de ce dépôt sur votre GitHub, choisir l'environnement cible dans Portainer, puis Stacks → Add stack → Repository. Renseigner l'URL du dépôt, une référence Git (idéalement un tag ou commit validé), le chemin Compose ci-dessous et les variables correspondantes. Utiliser le gestionnaire d'identifiants Portainer pour les dépôts privés, jamais un token dans l'URL versionnée.

| Stack | Chemin Compose | Particularités |
| --- | --- | --- |
| Minecraft | `compose/minecraft/compose.yaml` | EULA, version, RAM, port et BIND_IP |
| PostgreSQL | `compose/postgres/compose.yaml` | secret et chemins imports/backups **absolus sur l'hôte cible** |
| Web production | `templates/portainer/web.compose.yaml` | image déjà construite et poussée au registre |
| Data Lab | `templates/portainer/datalab.compose.yaml` | image déjà construite, token et chemins hôte absolus |

Les `.env` locaux de `config/` ne sont pas présents dans Git et ne sont pas transmis à Portainer. Copier les valeurs requises dans les variables de la stack Portainer. Pour activer pgAdmin sans dépendre du support des profils dans votre version Portainer, déployer la base par terminal avec `--admin`, ou préparer une variante explicite en retirant `profiles: [admin]` et en fournissant son mot de passe. Les scripts ne créent pas cette variante implicitement.

Les modèles du dossier `templates/portainer` n'ont aucun contexte de build relatif : ils fonctionnent aussi sur un moteur distant via Agent. Les fonctions de build Git et chemins relatifs diffèrent selon la version/édition Portainer. La procédure reproductible pour web/lab est de construire depuis Git puis pousser une image accessible au moteur cible :

```bash
docker build -t ghcr.io/VOTRE-COMPTE/portfolio:VERSION templates/nextjs
docker push ghcr.io/VOTRE-COMPTE/portfolio:VERSION
docker build -t ghcr.io/VOTRE-COMPTE/datalab:VERSION templates/datalab
docker push ghcr.io/VOTRE-COMPTE/datalab:VERSION
```

Ces commandes sont à exécuter volontairement, après authentification au registre. Un build simple ne produit que l'architecture du constructeur. Pour publier les deux architectures, utiliser un builder Buildx préparé et `docker buildx build --platform linux/amd64,linux/arm64 -t ... --push ...`, puis vérifier les manifests et tester les deux cibles. Les identifiants du registre privé doivent être configurés dans Portainer pour l'environnement cible.

Le nom de stack Portainer détermine les volumes et réseaux. Pour retrouver une stack créée en terminal, conserver le nom `homelab-<instance>`, mais ne pas tenter de la redéployer simultanément par les deux outils : choisir une autorité d'édition. Une stack externe peut être visible dans Portainer avec des fonctions d'édition limitées. Une nouvelle stack portant un autre nom crée des volumes vides. La mise à jour Git dans Portainer n'est pas un mécanisme de sauvegarde.

Portainer et Agent eux-mêmes sont de préférence amorcés par terminal pour conserver un accès de secours indépendant de l'interface. Les fichiers Compose principaux sont leurs modèles réutilisables.
