#!/bin/sh
set -eu

cd "$(dirname "$0")"

if [ ! -f .env ]; then
  echo 'Missing .env. Copy .env.example to .env and set local credentials.' >&2
  exit 1
fi

set -a
. ./.env
set +a

: "${DB_NAME:?Set DB_NAME in .env}"
: "${DB_USER:?Set DB_USER in .env}"
: "${DB_PASSWORD:?Set DB_PASSWORD in .env}"
: "${DRUPAL_ADMIN_USER:?Set DRUPAL_ADMIN_USER in .env}"
: "${DRUPAL_ADMIN_PASSWORD:?Set DRUPAL_ADMIN_PASSWORD in .env}"
: "${DRUPAL_SITE_NAME:?Set DRUPAL_SITE_NAME in .env}"

docker compose up -d --build
docker compose exec -T drupal chown -R www-data:www-data web/sites/default/files

if ! docker compose exec -T drupal vendor/bin/drush status --field=bootstrap 2>/dev/null | grep -q Successful; then
  docker compose exec -T drupal vendor/bin/drush site:install standard \
    --db-url="mysql://${DB_USER}:${DB_PASSWORD}@db/${DB_NAME}" \
    --site-name="$DRUPAL_SITE_NAME" \
    --account-name="$DRUPAL_ADMIN_USER" \
    --account-pass="$DRUPAL_ADMIN_PASSWORD" \
    -y
fi

docker compose exec -T drupal vendor/bin/drush en gsbc_demo -y
docker compose exec -T drupal vendor/bin/drush theme:enable claro -y
docker compose exec -T drupal vendor/bin/drush theme:enable gsbc -y
docker compose exec -T drupal vendor/bin/drush config:set system.theme admin claro -y
docker compose exec -T drupal vendor/bin/drush config:set system.theme default gsbc -y
docker compose exec -T drupal vendor/bin/drush php:eval '$storage = \Drupal::entityTypeManager()->getStorage("block"); foreach ($storage->loadByProperties(["theme" => "gsbc"]) as $block) { if ($block->getPluginId() !== "system_main_block") { $block->delete(); } }'
# drush cr rebuilds Drupal’s cache so updated CSS/Twig files are detected. 
docker compose exec -T drupal vendor/bin/drush cr

printf '\nReady: http://localhost:8080\nAdmin: http://localhost:8080/user/login?destination=/admin\n'
