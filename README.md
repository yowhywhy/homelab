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

### Windows : PowerShell (`.ps1`)

Les fichiers `.ps1` sont des scripts PowerShell. Sous Windows, utiliser les commandes suivantes depuis PowerShell :

```powershell
git clone <URL-DE-VOTRE-DEPOT> homelab
cd homelab
.\scripts\homelab.ps1 list
.\scripts\homelab.ps1 init all
# Remplir les fichiers config/*.env pour les services souhaités.
notepad config\postgres.env
# Définir au minimum POSTGRES_PASSWORD pour PostgreSQL.
.\scripts\homelab.ps1 config postgres
# À exécuter quand vous souhaitez réellement démarrer le service :
.\scripts\homelab.ps1 up postgres
```

### Linux / Raspberry Pi / WSL : Bash (`.sh`)

Les fichiers `.sh` sont des scripts Bash. Les utiliser sous Linux, sur le Raspberry Pi ou dans WSL sous Windows :

```bash
git clone <URL-DE-VOTRE-DEPOT> homelab
cd homelab
bash scripts/homelab.sh list
bash scripts/homelab.sh init all
# Remplir les fichiers config/*.env avec votre éditeur, par exemple :
nano config/postgres.env
# Définir au minimum POSTGRES_PASSWORD pour PostgreSQL.
bash scripts/homelab.sh config postgres
bash scripts/homelab.sh up postgres
```

### Initialiser puis remplir les configurations

`init all` crée les six fichiers `portainer.env`, `agent.env`, `minecraft.env`, `postgres.env`, `web.env` et `datalab.env` dans `config/`. Vous pouvez ensuite tous les remplir avant de choisir les services à lancer. La commande affiche les fichiers créés et ceux conservés : elle peut être relancée sans écraser vos valeurs existantes, notamment votre mot de passe PostgreSQL.

Pour préparer uniquement un service, utiliser `init postgres` (ou le nom d'une autre stack). Cette forme refuse toujours d'écraser une configuration existante. `all` est réservé à `init` et ne prend aucune option ; les commandes `config`, `up`, `down`, etc. ciblent un service à la fois.

L'initialisation ne démarre rien et ne nécessite pas Docker. Après édition, lancer `config <stack>` pour valider, puis `up <stack>` pour démarrer uniquement les services souhaités. Il n'est pas nécessaire de lancer toutes les stacks : Portainer Server est destiné à la tour, Agent aux machines secondaires.

Modifier les fichiers dans **`config/`**. Ceux de **`.validation/`** sont générés pour les vérifications avec des valeurs factices ; ne pas les utiliser pour vos services. Les fichiers locaux de `config/` sont ignorés par Git.

Le fichier `.env.example` racine est explicatif : les scripts passent toujours explicitement `config/<instance>.env`. Les valeurs du shell ont priorité sur le fichier env selon les règles Compose : éviter les variables homonymes exportées involontairement.

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

| Action | Effet |
| --- | --- |
| `list` | Afficher les stacks disponibles |
| `init all` | Préparer tous les fichiers env manquants, conserver ceux existants |
| `init <stack>` | Préparer une configuration unique sans écraser un fichier existant |
| `config <stack>` | Valider la configuration sans démarrer de conteneur |
| `up <stack>` | Construire/télécharger les images nécessaires et démarrer en arrière-plan |
| `logs <stack>` | Suivre les logs ; Ctrl+C quitte l'affichage sans arrêter le service |
| `down <stack>` | Arrêter les conteneurs en conservant les volumes de données |
| `update <stack>` | Mettre à jour les images et recréer les services |

Sous Windows / PowerShell :

```powershell
.\scripts\homelab.ps1 logs minecraft
.\scripts\homelab.ps1 down minecraft
.\scripts\homelab.ps1 update minecraft
.\scripts\homelab.ps1 up postgres -Admin
.\scripts\homelab.ps1 up web -Dev
.\scripts\homelab.ps1 init postgres -Instance postgres-test
.\scripts\homelab.ps1 up postgres -Instance postgres-test
```

Sous Linux / Bash :

```bash
bash scripts/homelab.sh logs minecraft
bash scripts/homelab.sh down minecraft
bash scripts/homelab.sh update minecraft
bash scripts/homelab.sh up postgres --admin
bash scripts/homelab.sh up web --dev
bash scripts/homelab.sh init postgres --instance postgres-test
bash scripts/homelab.sh up postgres --instance postgres-test
```

Pour la deuxième base, changer au minimum `PG_PORT`, éventuellement `PGADMIN_PORT`, dans `config/postgres-test.env`. Garder le même nom d'instance pour toutes ses commandes. Une instance nommée désigne une seule stack.

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
