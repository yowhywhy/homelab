# Validation de la V1

Vérifications réalisées le 11 novembre 2026, sans installer de service, construire d'image ni démarrer de conteneur :

- Les six Compose principaux passent `docker compose config --quiet` avec des valeurs factices pour les secrets.
- La fusion web + variante développement et le profil PostgreSQL + pgAdmin passent la même validation.
- Les modèles Portainer web et Data Lab passent cette validation avec des images de registre factices.
- Les deux scripts PowerShell sont analysés sans erreur par le parseur PowerShell.
- Les trois scripts Bash/shell passent `bash -n` ; la commande `list` fonctionne sous Bash et PowerShell.
- La génération des arguments PowerShell pour export/import PostgreSQL est vérifiée avec une fonction Docker simulée : projet isolé, nom de fichier et contenu du script transmis. Aucune commande SQL n'a été exécutée.
- `package-lock.json` est généré via npm sans exécuter les scripts de dépendances. Il résout notamment Next.js 16.4.6, React 19.3.1 et sharp 0.35.5. Ce verrou doit être conservé avec le modèle.

Relancer les dix validations Compose sous PowerShell :

```powershell
.\scripts\validate.ps1
```

Ce script utilise `.validation/` (ignoré par Git), une configuration Docker temporaire sans identifiants et des secrets factices. Il ne lance ni pull, ni build, ni conteneur et ne nécessite pas le moteur Docker. Les variables du shell peuvent toujours surcharger les fichiers env : utiliser une session sans variables applicatives préexportées pour une validation reproductible.

## À vérifier lors du premier déploiement

La validation Compose ne démontre pas la disponibilité d'un tag d'image, sa compatibilité ARM64, la réussite du build applicatif, les permissions des dossiers ni le bon fonctionnement d'un service. Les builds Next.js/Data Lab, les tests de restauration réels, les connexions réseau NetBird, le comportement de l'agent sous Docker Desktop et les essais Linux/ARM64 restent à faire sur les machines cibles après votre décision de les lancer.

Pour chaque machine : vérifier les manifests d'images, préparer les dossiers et droits, configurer les secrets et ports, lancer une stack à la fois, lire les logs et vérifier son état. Pour PostgreSQL, créer une petite table de test, exporter puis restaurer dans une instance vide distincte et comparer les données. Pour Minecraft, vérifier la conservation du monde après arrêt/redémarrage. Pour Next.js, vérifier les modes production et développement ; pour le Lab, sauvegarder un notebook puis redémarrer.

Les sources de référence sont liées dans chaque guide, notamment la [publication de sécurité Next.js du 14 octobre 2026](https://nextjs.org/blog/nextjs-security-update-october-14-2026). La maintenance des images et dépendances reste une opération régulière après livraison.
