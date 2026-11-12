# Execute dans le conteneur. Import dans la base configuree, sans --clean.
set -eu
source="/imports/$1"
test -r "$source" || { echo 'Fichier absent dans /imports' >&2; exit 1; }
case "$1" in
  *.sql) psql -X -v ON_ERROR_STOP=1 --single-transaction -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$source";;
  *) pg_restore --exit-on-error --single-transaction --no-owner --no-acl -U "$POSTGRES_USER" -d "$POSTGRES_DB" "$source";;
esac
