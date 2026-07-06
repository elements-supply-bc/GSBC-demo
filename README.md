# Gambling Support BC Drupal demonstration

A Drupal 11 demonstration of a content-managed Gambling Support BC homepage, including an alternate presentation aligned with the B.C. Design System. The implementation uses native Drupal content entities, Twig, CSS and Drupal behaviours; it does not require a front-end framework or asset build pipeline.

> **Demonstration status:** This repository is intended for technical evaluation and procurement demonstrations. It is not evidence of Government of British Columbia approval, production authorization or full WCAG conformance.

## Demonstration environments

| Experience | Local URL | Pantheon Dev |
|---|---|---|
| Original visual treatment | <http://localhost:8080/> | <https://dev-gsbc-demo-bc.pantheonsite.io/> |
| B.C. Design treatment | <http://localhost:8080/home> | <https://dev-gsbc-demo-bc.pantheonsite.io/home> |

Both pages use the same `Homepage` content type. The `B.C. design` field selects the visual treatment; content remains editable through Drupal.

## Solution highlights

- Drupal 11 Composer-managed project
- Structured `Homepage` fields for hero content, calls to action and support information
- Two visual treatments served by one content model and Twig template
- Locally hosted BC Sans fonts and B.C. digital colour tokens
- Responsive layout, visible keyboard focus and reduced-motion support
- Page-specific Drupal asset libraries with no inline CSS or JavaScript
- Docker Compose local development
- Pantheon Integrated Composer deployment
- Exported Drupal configuration committed under `config/`

## Architecture

```text
GitHub
  ├── Composer project and Drupal configuration
  ├── custom module: Homepage field definitions
  └── custom theme: Twig, CSS, JavaScript and fixed brand assets
          │
          ▼
Pantheon Integrated Composer
          │
          ├── Drupal database: content, users and active configuration
          └── public files: editor-uploaded hero images and documents
```

Code, configuration and content have different deployment lifecycles:

| Asset | Source of truth | Deployment method |
|---|---|---|
| PHP, Twig, CSS, JavaScript and fixed theme images | Git | GitHub/Pantheon build |
| Drupal site structure and settings | `config/*.yml` | Drush configuration import |
| Nodes, users, aliases and active configuration | Database | Content editing or database migration |
| Editor-uploaded media | `sites/default/files` | Drupal upload or files migration |

## Local development

### Requirements

- Docker Desktop with Docker Compose
- Git

### Start the project

```bash
cp .env.example .env
# Replace every change-me value in .env.
./start.sh
```

The initial build downloads Composer dependencies and installs Drupal. When it completes, open <http://localhost:8080>.

- Administration: <http://localhost:8080/admin>
- Sign in: <http://localhost:8080/user/login>
- Credentials: values from the ignored local `.env`

The installation credentials are used only when creating a new database. Change existing accounts through Drupal user administration.

### Stop or reset

```bash
./stop.sh
```

Docker volumes preserve the database and uploaded files. To permanently remove local content and start again:

```bash
docker compose down -v
```

This command deletes local Docker volumes and cannot be undone.

## Content administration

Manage homepage nodes at <http://localhost:8080/admin/content>.

Important fields include:

- Hero title and image
- Primary and secondary calls to action
- Introduction and support information
- `B.C. design`, which enables the alternate presentation

Hero photographs are Drupal-managed content. Drupal stores the file under `sites/default/files`, while the node stores a file-entity reference and alternative text. Fixed logos and brand artwork remain in the theme and are deployed through Git.

The current image field supports uploads but does not provide an existing-file browser. If reusable editorial media becomes a broader requirement, migrate the field to a Drupal Media reference using the Media Library widget.

## Theme development

The custom theme is under `web/themes/custom/gsbc`.

```text
css/base.css          Global typography and accessibility foundations
css/homepage.css      Shared homepage layout and components
css/homepage-bc.css   B.C. Design treatment and responsive overrides
templates/            Homepage and component Twig templates
js/navigation.js      Drupal behaviour for responsive navigation
assets/               Fixed fonts, logos and theme imagery
```

Drupal libraries are declared in `gsbc.libraries.yml` and attached from Twig only where needed. After changing Twig, YAML, CSS or JavaScript, rebuild caches:

```bash
docker compose exec -T drupal vendor/bin/drush cache:rebuild
```

## Drupal configuration

Export active configuration after changing fields, displays, modules or other administrative settings:

```bash
docker compose exec -T drupal \
  vendor/bin/drush config:export -y --destination=/opt/drupal/config
```

Preview imports before applying them:

```bash
docker compose exec -T drupal \
  vendor/bin/drush config:import --source=/opt/drupal/config --no --diff
```

Configuration export does not include node content, users or uploaded files.

## Pantheon deployment

Pantheon is connected to the GitHub repository through external version control. A push to the connected branch triggers Integrated Composer; a custom Docker image is not required.

```bash
git push origin master

COMMIT=$(git rev-parse --short HEAD)
terminus workflow:wait gsbc-demo-bc.dev --commit="$COMMIT" --max=900
```

For releases that include Drupal database or configuration updates:

```bash
terminus remote:drush gsbc-demo-bc.dev -- updatedb -y
terminus remote:drush gsbc-demo-bc.dev -- config:import --no --diff
# Review the preview before applying configuration.
terminus remote:drush gsbc-demo-bc.dev -- config:import -y
terminus remote:drush gsbc-demo-bc.dev -- cache:rebuild
```

Do not import a local database over an active environment without a reviewed migration plan; doing so replaces remote content and user data.

## Quality and accessibility

The demonstration is designed toward WCAG 2.2 Level AA and the B.C. Accessibility and Inclusion Toolkit. The implementation supports accessibility in the following ways:

- Semantic Twig templates provide one page heading, ordered section headings and recognizable header, navigation, main-content and footer regions.
- A keyboard-focusable skip link moves users to `#main-content`. Native links, buttons and disclosure elements retain their expected keyboard behaviour, and visible focus styles do not depend on colour alone.
- The Drupal hero-image field requires alternative text. Fixed brand images also have concise accessible names.
- The B.C. hero uses a dark overlay behind its large white heading. The current image measures approximately 7.8:1 on desktop and 5.7:1 on mobile, above the 3:1 minimum for large text. Primary and secondary button text measures approximately 12.6:1 against its background.
- Desktop calls to action sit over the light side of the hero treatment. On mobile they move below the image, stack at full width and retain a 52-pixel activation height.
- The mobile hero is reduced to 200 pixels high so more of the wide source image remains visible without distortion. The heading remains real text and uses a stronger mobile overlay to preserve contrast across the crop.
- Responsive layouts reflow without horizontal page scrolling at a 320-pixel viewport. Reduced-motion preferences disable smooth scrolling.
- Accessibility content is stored in structured Drupal fields so editors can update it without changing templates.

These choices support accessibility but do not establish full WCAG conformance. Before each release, test representative routes at narrow and wide widths, at 200% and 400% zoom, with keyboard-only navigation and with a supported screen-reader/browser combination. Include people who use assistive technology in usability testing before a public launch.

Production readiness also requires:

- Formal WCAG Level AA testing with representative authored content
- Confirmation of image copyright and model consent
- Privacy, security, analytics, records and data-residency review
- GCPE, Web Oversight Committee, CMS Lite exemption, domain and branding approvals where applicable
- Defined content ownership, review frequency and archival process

Implementation work alone does not grant these approvals.

## Secrets and security

- `.env` is local-only and must not be committed.
- Pantheon provisions and injects its own database credentials.
- API keys and other service secrets must use environment-appropriate secret storage, not Drupal configuration YAML.
- Commit both `composer.json` and `composer.lock`; do not commit `vendor/`, Drupal core or generated public files.

## Repository structure

```text
config/                              Exported Drupal configuration
web/modules/custom/gsbc_demo/        Homepage content model installation
web/themes/custom/gsbc/              Custom presentation layer
web/sites/default/settings.php       Pantheon and config-sync settings
Dockerfile                           Local Drupal image
docker-compose.yml                   Local services and persistent volumes
pantheon.upstream.yml                Pantheon platform settings
start.sh / stop.sh                   Local environment commands
```

## Licensing and assets

The project is marked proprietary for demonstration purposes. Third-party fonts, photography and B.C. identity assets remain subject to their respective licences, usage rules, copyright permissions and model-consent requirements.
