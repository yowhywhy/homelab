# Configuration locale

Les scripts `init` copient les exemples dans ce dossier sans écraser les fichiers existants.
Un fichier par stack ou instance : `postgres.env`, `postgres-test.env`, etc.
Ils sont ignorés par Git. Protéger ce dossier et ne jamais envoyer ses fichiers dans une PR.
Les secrets Compose contenant `$` doivent être placés entre apostrophes dans les fichiers env.
Les scripts ne sourcent et n'exécutent jamais ces fichiers.
