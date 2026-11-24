# Modèles de stacks Portainer

Pour Cloudflare Tunnel, utiliser `compose/cloudflare-tunnel/compose.yaml`. Le modèle `web-proxy.compose.yaml` connecte une image Next.js au réseau externe `homelab-proxy` sans publier de port hôte. Voir le [guide Cloudflare Tunnel](../../docs/cloudflare-tunnel.md) pour créer le réseau sur le moteur cible et configurer les variables et routes.

Utiliser les Compose Minecraft et PostgreSQL directement depuis ce dépôt Git. Pour web et Data Lab, utiliser les modèles de ce dossier avec une image publiée : aucun build distant ni chemin source local n'est requis. Renseigner les variables dans Portainer ; elles ne proviennent pas des fichiers `config/` de votre poste.

La procédure complète, les chemins et les contraintes d'architecture sont décrits dans [le guide Portainer](../../docs/portainer.md).
