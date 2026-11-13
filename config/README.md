# Configuration locale

Les scripts `init` copient les exemples dans ce dossier sans écraser les fichiers existants.

Préparer tous les fichiers en une commande :

```powershell
# Windows / PowerShell (.ps1)
.\scripts\homelab.ps1 init all
```

```bash
# Linux / Raspberry Pi / WSL / Bash (.sh)
bash scripts/homelab.sh init all
```

Les fichiers existants sont conservés ; seuls les fichiers manquants sont créés. Remplir ensuite les fichiers `.env` de ce dossier, puis valider et démarrer chaque service souhaité. Aucun conteneur n'est lancé par `init`. Les fichiers de `.validation/` contiennent des valeurs de test et ne sont pas à modifier.

Un fichier par stack ou instance : `postgres.env`, `postgres-test.env`, etc.
Ils sont ignorés par Git. Protéger ce dossier et ne jamais envoyer ses fichiers dans une PR.
Les secrets Compose contenant `$` doivent être placés entre apostrophes dans les fichiers env.
Les scripts ne sourcent et n'exécutent jamais ces fichiers.
