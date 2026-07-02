# Gambling Support BC Drupal demo

A Drupal 11 homepage demo based on <https://www.gamblingsupportbc.ca/>. It uses an editable `Homepage` content type and a native Twig/CSS theme—no React or front-end build step.

## Start it

You need [Docker Desktop](https://www.docker.com/products/docker-desktop/) running.

```bash
cp .env.example .env
# Edit .env and replace every change-me value.
./start.sh
```

The first start downloads Drupal and may take a few minutes. Then open <http://localhost:8080>.

- Drupal admin: <http://localhost:8080/user/login>
- Admin credentials: your ignored `.env` file

The credentials in `.env` are used only when installing a fresh database. To
change an account in an existing database, use Drupal's user administration.

## Stop it

```bash
./stop.sh
```

Your database is kept in a Docker volume. To erase the demo completely and start fresh:

```bash
docker compose down -v
```

## Edit it

- Homepage content: open <http://localhost:8080/admin/content>, then edit the **Home** node
- Direct edit URL: <http://localhost:8080/node/1/edit>
- Homepage fields are created in `web/modules/custom/gsbc_demo/gsbc_demo.install`
- Homepage markup: `web/themes/custom/gsbc/templates/node--homepage.html.twig`
- Styles: `web/themes/custom/gsbc/css/style.css`
- Menu behaviour: `web/themes/custom/gsbc/js/navigation.js`

`Homepage` is a content type; `Home` is a node of that type. A content-type machine name is not automatically a public URL. Saved nodes normally use `/node/{id}` unless you give them a URL alias.

After editing Twig or YAML, clear Drupal's cache:

```bash
docker compose exec drupal vendor/bin/drush cr
```

## Composer and configuration

Composer owns Drupal core, Drush, and Pantheon integration. Commit both
`composer.json` and `composer.lock`; do not commit `vendor/`, Drupal core, or
contributed extensions.

Export active Drupal configuration before committing configuration changes:

```bash
docker compose exec drupal vendor/bin/drush cex --destination=/opt/drupal/config -y
```

Configuration is code. Content, users, uploaded files, and the two homepage
nodes remain in the database/files volume and require a separate migration.

## Optional DDEV workflow

After installing DDEV:

```bash
ddev start
ddev composer install
```

Import a database before expecting this DDEV site to contain the current
homepage content.

## Pantheon sandbox

1. Commit and push this repository to GitHub.
2. In Pantheon, create a Drupal 11 Composer Managed sandbox. If your workspace
   supports Pantheon's GitHub integration, connect this existing repository;
   otherwise add the Pantheon Git URL as a remote and push to it.
3. Wait for Integrated Composer to build the Dev environment.
4. Migrate the local database and `web/sites/default/files` to Pantheon. The
   database contains the homepage nodes and the installed-module state.
5. On Pantheon Dev, run database updates, import configuration, and rebuild
   caches:

   ```bash
   terminus drush SITE.dev -- updatedb -y
   terminus drush SITE.dev -- config:import --no --diff
   # Review the preview, then run config:import -y when it is correct.
   terminus drush SITE.dev -- cache:rebuild
   ```

6. Verify `/`, `/home`, admin login, image uploads, and HTTPS on Dev before
   promoting anything to Test or Live.

The hero photograph is loaded from the source site's public URL because its server did not permit reliable asset export. Replace that URL in `style.css` with an approved local image before publishing.
