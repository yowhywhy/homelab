# Execute dans le conteneur par homelab.ps1 / homelab.sh.
set -eu
target="/backups/$1"
test ! -e "$target" || { echo 'Sauvegarde deja presente' >&2; exit 1; }
tmp="$(mktemp /backups/.dump-XXXXXX)"
trap 'rm -f "$tmp"' EXIT HUP INT TERM
case "$1" in
  *.sql) pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --no-owner --no-acl -f "$tmp";;
  *) pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --format=custom --no-owner --no-acl -f "$tmp";;
esac
mv "$tmp" "$target"
echo "Sauvegarde terminee: $target"
