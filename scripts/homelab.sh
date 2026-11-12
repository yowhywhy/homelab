#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
action="${1:-list}"
if [[ "$action" == list ]]; then
  printf '%s\n' portainer agent minecraft postgres web datalab
  exit 0
fi
stack="${2:?Usage: bash scripts/homelab.sh ACTION STACK [--instance NOM] [--dev] [--admin] [--file NOM]}"
shift 2
case "$stack" in portainer|agent|minecraft|postgres|web|datalab) ;; *) echo 'Stack inconnue' >&2; exit 1;; esac
instance="$stack"; dev=false; admin=false; file=''
while [[ $# -gt 0 ]]; do
  case "$1" in
    --instance) instance="${2:?Nom manquant}"; shift 2;;
    --file) file="${2:?Fichier manquant}"; shift 2;;
    --dev) dev=true; shift;;
    --admin) admin=true; shift;;
    *) echo "Option inconnue: $1" >&2; exit 1;;
  esac
done
[[ "$instance" =~ ^[a-z0-9][a-z0-9_-]*$ ]] || { echo 'Nom instance invalide' >&2; exit 1; }
if $dev && [[ "$stack" != web ]]; then echo '--dev exige web' >&2; exit 1; fi
if $admin && [[ "$stack" != postgres ]]; then echo '--admin exige postgres' >&2; exit 1; fi
envfile="$root/config/$instance.env"
if [[ "$action" == init ]]; then
  [[ ! -e "$envfile" ]] || { echo "Configuration deja presente: $envfile" >&2; exit 1; }
  cp "$root/compose/$stack/.env.example" "$envfile"
  echo "Configurer $envfile avant demarrage."
  exit 0
fi
[[ -f "$envfile" ]] || { echo 'Executer init avec la meme instance auparavant.' >&2; exit 1; }
dc=(docker compose --project-name "homelab-$instance" --env-file "$envfile" -f "$root/compose/$stack/compose.yaml")
if $dev; then dc+=(-f "$root/compose/web/compose.dev.yaml"); fi
if $admin; then dc+=(--profile admin); fi
case "$action" in
  config) "${dc[@]}" config --quiet;;
  up) "${dc[@]}" up -d --build --remove-orphans;;
  down) "${dc[@]}" down;;
  logs) "${dc[@]}" logs --follow --tail 100;;
  update)
    case "$stack" in web|datalab) "${dc[@]}" build --pull;; *) "${dc[@]}" pull;; esac
    "${dc[@]}" up -d --remove-orphans;;
  backup|restore)
    [[ "$stack" == postgres ]] || { echo 'backup/restore exigent postgres' >&2; exit 1; }
    if [[ -z "$file" && "$action" == backup ]]; then file="$instance-$(date +%Y%m%d-%H%M%S).dump"; fi
    [[ "$file" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]*\.(sql|dump|backup)$ ]] || { echo 'Fournir --file NOM.sql, NOM.dump ou NOM.backup sans chemin' >&2; exit 1; }
    "${dc[@]}" exec -T postgres sh -ec "$(cat "$root/scripts/postgres-$action.sh")" homelab "$file";;
  *) echo 'Actions: list init config up down logs update backup restore' >&2; exit 1;;
esac
