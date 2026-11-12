# Homelab portable

Infrastructure Docker Compose indépendante de Portainer, pour une tour Linux, un Raspberry Pi ARM64 et un portable Linux ou Windows (Docker Desktop, conteneurs Linux).

```text
Tour principale : Docker + Portainer Server + stacks au choix
                         │ réseau privé NetBird (sur les hôtes)
                         ├── Raspberry Pi : Docker + Agent + stacks au choix
                         └── Portable : Docker Desktop/Linux + Agent + stacks au choix
```

Chaque machine stocke ses données localement. Git transporte les configurations et le code, jamais les données ni les secrets. Portainer administre les moteurs distants ; aucune réplication, migration automatique ou haute disponibilité n'est prévue.

```text
compose/           portainer, agent, minecraft, postgres, web, datalab
templates/         nextjs, datalab, portainer
scripts/           commandes Bash et PowerShell, sauvegarde/import PostgreSQL
config/            fichiers .env locaux ignorés par Git
docs/              installation, exploitation, réseau, Portainer, validation
imports/           fichiers volumineux locaux (créé au premier montage)
backups/           exports locaux (créé au premier montage)
data/              sorties locales du Data Lab
```

## Démarrage

Prérequis : Git, Docker Engine avec plugin Compose récent, ou Docker Desktop en mode Linux avec backend WSL2 ; Bash sous Linux ou PowerShell 5.1+ sous Windows. Prévoir de l'espace disque, une connexion pour télécharger les images et les droits d'accès au moteur Docker. Aucun script n'installe Docker, NetBird ou un service système.

```powershell
git clone <URL-DE-VOTRE-DEPOT> homelab
cd homelab
.\scripts\homelab.ps1 list
.\scripts\homelab.ps1 init postgres
# Éditer config/postgres.env et définir POSTGRES_PASSWORD.
.\scripts\homelab.ps1 config postgres
# À exécuter quand vous souhaitez réellement démarrer le service :
.\scripts\homelab.ps1 up postgres
```

```bash
git clone <URL-DE-VOTRE-DEPOT> homelab
cd homelab
bash scripts/homelab.sh list
bash scripts/homelab.sh init postgres
# Éditer config/postgres.env et définir POSTGRES_PASSWORD.
bash scripts/homelab.sh config postgres
bash scripts/homelab.sh up postgres
```

Répéter `init`, édition, `config`, `up` pour chaque stack choisie. `init` refuse d'écraser une configuration existante. Le fichier `.env.example` racine est explicatif : les scripts passent toujours explicitement `config/<instance>.env`. Les valeurs du shell ont priorité sur le fichier env selon les règles Compose : éviter les variables homonymes exportées involontairement.

| Stack | Accès local par défaut | Configuration nécessaire |
| --- | --- | --- |
| portainer | https://127.0.0.1:9443 | `AGENT_SECRET`, premier compte administrateur |
| agent | 127.0.0.1:9001 | même `AGENT_SECRET`, adresse réseau privée |
| minecraft | 127.0.0.1:25565 | accepter l'EULA, version et RAM |
| postgres | 127.0.0.1:5432 | mot de passe ; pgAdmin optionnel : 5050 |
| web | http://127.0.0.1:3000 | modèle fourni ou chemin vers votre application |
| datalab | http://127.0.0.1:8888 | `JUPYTER_TOKEN` aléatoire |

Tous les ports écoutent sur loopback par défaut. Renseigner `BIND_IP` avec l'adresse NetBird de la machine pour un accès privé Linux. Lire les particularités Docker Desktop dans [installation et réseau](docs/installation.md) avant d'exposer un agent. Ne pas publier ces services directement sur Internet.

## Commandes usuelles

```powershell
.\scripts\homelab.ps1 logs minecraft
.\scripts\homelab.ps1 down minecraft
.\scripts\homelab.ps1 update minecraft
.\scripts\homelab.ps1 up postgres -Admin
.\scripts\homelab.ps1 up web -Dev
.\scripts\homelab.ps1 init postgres -Instance postgres-test
.\scripts\homelab.ps1 up postgres -Instance postgres-test
```

Sous Bash, remplacer le préfixe par `bash scripts/homelab.sh` et les options par `--admin`, `--dev`, `--instance postgres-test`. Pour la deuxième base, changer au minimum `PG_PORT`, éventuellement `PGADMIN_PORT`, dans `config/postgres-test.env`. Garder le même nom d'instance pour toutes ses commandes. Une instance nommée désigne une seule stack.

`down` conserve les volumes. `update` tire les images distantes ou reconstruit web/lab avec des bases récentes, puis recrée les services : interruption possible. Il ne met pas à jour Git ni les dépendances npm/pip verrouillées. Sauvegarder avant une mise à jour ; ne pas changer une version majeure PostgreSQL sur un volume existant. Utiliser les mêmes options `-Dev`/`-Admin` pour les opérations sur la variante choisie ; repasser `up` sans `-Dev` revient en production.

Sans script, les stacks restent utilisables :

```bash
docker compose -p homelab-postgres --env-file config/postgres.env -f compose/postgres/compose.yaml up -d
```

## Services et documentation

- [Installer les trois machines et NetBird](docs/installation.md).
- [Configurer Minecraft, Next.js et le Data Lab](docs/services.md).
- [PostgreSQL : instances, imports volumineux, sauvegardes et réglages](docs/postgres.md).
- [Administrer plusieurs machines avec Portainer et déployer depuis Git](docs/portainer.md).
- [Persistance, mises à jour et récupération](docs/operations.md).
- [Vérifications réalisées et limites](docs/validation.md).

Les exemples sont volontairement incomplets pour les secrets ; un mot de passe vide bloque PostgreSQL, Portainer/Agent et Jupyter à la validation. Minecraft exige votre acceptation de l'[EULA](https://www.minecraft.net/eula). Les images utilisent des tags lisibles, parfois mobiles : pour figer un déploiement, relever les digests après vérification de l'architecture et conserver les références validées dans votre configuration locale.
