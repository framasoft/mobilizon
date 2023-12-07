# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 4.0.1 (2023-12-07)

### Security issues

This release fixes different security issues reported by the potsda.mn collective. Please make sure to upgrade as soon as possible.

### Added

- Added a CLI task to test if emails configuration works properly

### Fixed
- Fixes XSS issues in groups descriptions, report contents, messages from anonymous participations and resources descriptions
- Fixes Docker configuration that prevented the image to launch

### Changed

- Added back Debian Buster builds

### Complete changelog

* build(packages): add back Debian Buster as it seems people are still using it ([795ef24](https://framagit.org/framasoft/mobilizon/commits/795ef24))
* build(packages): remove alpine packages as there's no demand for it ([0caaf2b](https://framagit.org/framasoft/mobilizon/commits/0caaf2b))
* Translated using Weblate (Croatian) ([9c88fae](https://framagit.org/framasoft/mobilizon/commits/9c88fae))
* Translated using Weblate (Croatian) ([623f4ee](https://framagit.org/framasoft/mobilizon/commits/623f4ee))
* Translated using Weblate (Croatian) ([1162dd0](https://framagit.org/framasoft/mobilizon/commits/1162dd0))
* Translated using Weblate (Galician) ([97c53bb](https://framagit.org/framasoft/mobilizon/commits/97c53bb))
* Translated using Weblate (Galician) ([e08b057](https://framagit.org/framasoft/mobilizon/commits/e08b057))
* Translated using Weblate (Galician) ([ec5e436](https://framagit.org/framasoft/mobilizon/commits/ec5e436))
* Translated using Weblate (Korean) ([1a1ad52](https://framagit.org/framasoft/mobilizon/commits/1a1ad52))
* Translated using Weblate (Korean) ([7b4c31d](https://framagit.org/framasoft/mobilizon/commits/7b4c31d))
* fix: always consider report content as text ([ffff379](https://framagit.org/framasoft/mobilizon/commits/ffff379))
* fix: sanitize descriptions from resources ([dc6647f](https://framagit.org/framasoft/mobilizon/commits/dc6647f))
* fix(config): fix setting path for Mobilizon.Service.SiteMap ([7d725bd](https://framagit.org/framasoft/mobilizon/commits/7d725bd))
* fix(docker): fix getting configuration value from env MOBILIZON_SMTP_TLS ([28063bd](https://framagit.org/framasoft/mobilizon/commits/28063bd)), closes [#1381](https://framagit.org/framasoft/mobilizon/issues/1381)
* fix(docker): fix getting default value for MOBILIZON_SMTP_SSL env ([126727b](https://framagit.org/framasoft/mobilizon/commits/126727b))
* fix(docker): use separate env for tzdata dir path ([9907f88](https://framagit.org/framasoft/mobilizon/commits/9907f88))
* fix(emails): use tls_certificate_check to add tls config for mailer ([db38550](https://framagit.org/framasoft/mobilizon/commits/db38550))
* fix(front): anonymous participant text is plain text, avoid using v-html ([2c12fbf](https://framagit.org/framasoft/mobilizon/commits/2c12fbf))
* fix(front): fix editing group ([935799f](https://framagit.org/framasoft/mobilizon/commits/935799f))
* fix(front): fix XSS because of bad operations when setting the group's summary ([ded59be](https://framagit.org/framasoft/mobilizon/commits/ded59be))
* fix(front): put correct value for CONVERSATION_LIST enum value ([94bf2e5](https://framagit.org/framasoft/mobilizon/commits/94bf2e5))
* fix(graphql): set default value for resource type parameter ([09f4132](https://framagit.org/framasoft/mobilizon/commits/09f4132))
* feat(cli): add command to test emails send correctly ([7210f86](https://framagit.org/framasoft/mobilizon/commits/7210f86))
* feat(docker): allow to configure loglevel at runtime through env variable ([4855af8](https://framagit.org/framasoft/mobilizon/commits/4855af8))
* test: add new tests for XSS in actors summary ([58e50e3](https://framagit.org/framasoft/mobilizon/commits/58e50e3))
* style: linting front-end ([41227d9](https://framagit.org/framasoft/mobilizon/commits/41227d9))
* refactor(activitypub): handle failure finding public key in actor keys ([5b337f9](https://framagit.org/framasoft/mobilizon/commits/5b337f9))


## 4.0.0 (2023-12-05)

### Breaking changes

#### Release (binary package) installations

- We now produce packages for different distributions targets (Debian Bookworm, Debian Bullseye, Ubuntu Jammy, Ubuntu Focal, Ubuntu Bionic, Fedora 38 and Fedora 39). Be sure to pick the right one for your system, as there can be issues with OpenSSL versions differing from inside the Mobilizon package and on your system.
- The `https://joinmobilizon.org/latest-package` URL now links to the latest package builded against Debian Bookworm. Make sure to follow the documentation if you're not using this.
- There's also an `arm64` package build on Debian Bullseye for now.

#### Source installations
  - Elixir 15 is now required
  - The content of the `js` directory is now at the root of the repository, so you don't need to `cd js` anymore
  - No need for `yarn` anymore, simply use `npm` instead for `npm i` and `npm run build`

### New features

- Event organizers and groups can be contacted through private messages (including PMs from 3rd-party micro-blogging fediverse services)
- Event organizers can send private announcements to event participants (approved or not)


### Improvements
- Anonymous participation e-mails now contain links to cancel your participation
- ActivityPub improvements for compatibility with https://event-federation.eu
- ICS export fixes for descriptions and adding event status

### Changes since 4.0.0-rc.1

* refactor: to lower cyclomatic complexity ([147096c](https://framagit.org/framasoft/mobilizon/commits/147096c))
* fix(activitypub): compact ical:status in activitystream data ([5e8f9af](https://framagit.org/framasoft/mobilizon/commits/5e8f9af)), closes [#1378](https://framagit.org/framasoft/mobilizon/issues/1378)
* fix(activitypub): fix receiving comments ([f1084c1](https://framagit.org/framasoft/mobilizon/commits/f1084c1))
* fix(backend): handle ecto errors when fetching and create entities ([89d1ee4](https://framagit.org/framasoft/mobilizon/commits/89d1ee4))
* fix(front): fix tag loading ([f81472e](https://framagit.org/framasoft/mobilizon/commits/f81472e))
* fix(front): make recipient field placeholder translatable ([10ce812](https://framagit.org/framasoft/mobilizon/commits/10ce812))
* fix(front): only show participants & announcements menu items to organizers ([c4d2ec6](https://framagit.org/framasoft/mobilizon/commits/c4d2ec6))
* Translated using Weblate (Croatian) ([a26ff98](https://framagit.org/framasoft/mobilizon/commits/a26ff98))
* Translated using Weblate (Croatian) ([1683f01](https://framagit.org/framasoft/mobilizon/commits/1683f01))
* Translated using Weblate (Croatian) ([aa7f870](https://framagit.org/framasoft/mobilizon/commits/aa7f870))
* Translated using Weblate (Croatian) ([1ce34ea](https://framagit.org/framasoft/mobilizon/commits/1ce34ea))
* Translated using Weblate (Croatian) ([5e7edc0](https://framagit.org/framasoft/mobilizon/commits/5e7edc0))
* Translated using Weblate (Croatian) ([d777d88](https://framagit.org/framasoft/mobilizon/commits/d777d88))
* Translated using Weblate (Croatian) ([0118d97](https://framagit.org/framasoft/mobilizon/commits/0118d97))
* Translated using Weblate (Croatian) ([805e931](https://framagit.org/framasoft/mobilizon/commits/805e931))

## 4.0.0-rc.1 (2023-12-04)

* fix: prevent sending group physical address if it's empty and allow empty text for timezone ([32caebb](https://framagit.org/framasoft/mobilizon/commits/32caebb)), closes [#1357](https://framagit.org/framasoft/mobilizon/issues/1357)
* fix(activitypub): add missing externalParticipationUrl context ([8795576](https://framagit.org/framasoft/mobilizon/commits/8795576)), closes [#1376](https://framagit.org/framasoft/mobilizon/issues/1376)
* fix(backend): only send suspension notification emails when actor's suspended and not just deleted ([9e41bc1](https://framagit.org/framasoft/mobilizon/commits/9e41bc1))
* docs(nginx): improve nginx configuration ([6c992ca](https://framagit.org/framasoft/mobilizon/commits/6c992ca))

## 4.0.0-beta.2 (2023-12-01)

* test: fix tests using verified routes ([5fcf3d5](https://framagit.org/framasoft/mobilizon/commits/5fcf3d5))
* feat: add links to cancel anonymous participations in emails ([9e6b232](https://framagit.org/framasoft/mobilizon/commits/9e6b232))
* feat(background): add a job to refresh participant stats ([11e42d6](https://framagit.org/framasoft/mobilizon/commits/11e42d6))
* feat(front): add dedicated page and route for event announcements ([d831dff](https://framagit.org/framasoft/mobilizon/commits/d831dff))
* chore(i18n): update backend translations ([6df16ef](https://framagit.org/framasoft/mobilizon/commits/6df16ef))
* fix: fix creating participant stats ([3f2a88f](https://framagit.org/framasoft/mobilizon/commits/3f2a88f))
* refactor: use Phoenix verified routes ([b315e1d](https://framagit.org/framasoft/mobilizon/commits/b315e1d))

## 4.0.0-beta.1 (2023-11-30)

* fix: add a final fallback if we have default_language: nil in instance config ([cd53062](https://framagit.org/framasoft/mobilizon/commits/cd53062))
* fix: build pictures at correct location and fix Plug.Static ([3c288c5](https://framagit.org/framasoft/mobilizon/commits/3c288c5))
* fix: don't show passed/finished events in related events section ([69e4a5c](https://framagit.org/framasoft/mobilizon/commits/69e4a5c))
* fix: fix Dockerfile copying assets path ([16cd377](https://framagit.org/framasoft/mobilizon/commits/16cd377))
* fix: normalize suggested username ([4960387](https://framagit.org/framasoft/mobilizon/commits/4960387))
* fix: set correct watcher config for E2E tests ([f47889b](https://framagit.org/framasoft/mobilizon/commits/f47889b))
* fix: various fixes ([b635937](https://framagit.org/framasoft/mobilizon/commits/b635937))
* fix(announcements): load group announcements ([7ef85fe](https://framagit.org/framasoft/mobilizon/commits/7ef85fe))
* fix(api): allow localhost as a valid uri host for applications ([49b070d](https://framagit.org/framasoft/mobilizon/commits/49b070d))
* fix(api): fix allowing posting event private announcement ([1831495](https://framagit.org/framasoft/mobilizon/commits/1831495))
* fix(docker): add sitemap folder ([bd38449](https://framagit.org/framasoft/mobilizon/commits/bd38449))
* fix(docker): allow to configure SMTP TLS ([2ecdf05](https://framagit.org/framasoft/mobilizon/commits/2ecdf05))
* fix(docker): convert smtp tls sni to char list ([b3be7c6](https://framagit.org/framasoft/mobilizon/commits/b3be7c6))
* fix(export): fix iCalendar export description HTML conversion ([d7daafc](https://framagit.org/framasoft/mobilizon/commits/d7daafc)), closes [#888](https://framagit.org/framasoft/mobilizon/issues/888)
* fix(front): hide all categories card if we don't have even one ([5e86ef1](https://framagit.org/framasoft/mobilizon/commits/5e86ef1))
* fix(histoire): fix URL to Framapiaf avatars ([0613f7f](https://framagit.org/framasoft/mobilizon/commits/0613f7f))
* fix(i18n): fix typos in translation sources ([2ecd55d](https://framagit.org/framasoft/mobilizon/commits/2ecd55d))
* fix(i18n): update spanish translations ([cfebc35](https://framagit.org/framasoft/mobilizon/commits/cfebc35))
* add simplified Chinese mapping ([02af9a4](https://framagit.org/framasoft/mobilizon/commits/02af9a4))
* Added translation using Weblate (Korean) ([a11fab6](https://framagit.org/framasoft/mobilizon/commits/a11fab6))
* Added translation using Weblate (Korean) ([c529a83](https://framagit.org/framasoft/mobilizon/commits/c529a83))
* Added translation using Weblate (Tatar) ([cefdaf8](https://framagit.org/framasoft/mobilizon/commits/cefdaf8))
* Fix docker development: ([9705978](https://framagit.org/framasoft/mobilizon/commits/9705978))
* fix fullAddressAutocomplete component not loading results ([83da88c](https://framagit.org/framasoft/mobilizon/commits/83da88c))
* Fix typo in ctl help text ([495d163](https://framagit.org/framasoft/mobilizon/commits/495d163))
* Fix typos ([66e89b9](https://framagit.org/framasoft/mobilizon/commits/66e89b9))
* introduce VITE_HOST env var and pass it to the node watcher vite --host ([bfb7e3c](https://framagit.org/framasoft/mobilizon/commits/bfb7e3c))
* remove unnecessary function ([8a1b122](https://framagit.org/framasoft/mobilizon/commits/8a1b122))
* resolve result promise in a shorter way ([f81804d](https://framagit.org/framasoft/mobilizon/commits/f81804d))
* Translated using Weblate (Croatian) ([e510e09](https://framagit.org/framasoft/mobilizon/commits/e510e09))
* Translated using Weblate (Czech) ([d702ca2](https://framagit.org/framasoft/mobilizon/commits/d702ca2))
* Translated using Weblate (Czech) ([9224f89](https://framagit.org/framasoft/mobilizon/commits/9224f89))
* Translated using Weblate (Czech) ([c14dffb](https://framagit.org/framasoft/mobilizon/commits/c14dffb))
* Translated using Weblate (Czech) ([a7d70d5](https://framagit.org/framasoft/mobilizon/commits/a7d70d5))
* Translated using Weblate (French) ([c7ba003](https://framagit.org/framasoft/mobilizon/commits/c7ba003))
* Translated using Weblate (German) ([7732f87](https://framagit.org/framasoft/mobilizon/commits/7732f87))
* Translated using Weblate (Indonesian) ([d065193](https://framagit.org/framasoft/mobilizon/commits/d065193))
* Translated using Weblate (Italian) ([b5e9f62](https://framagit.org/framasoft/mobilizon/commits/b5e9f62))
* Translated using Weblate (Italian) ([e8e1a62](https://framagit.org/framasoft/mobilizon/commits/e8e1a62))
* Translated using Weblate (Italian) ([84fc175](https://framagit.org/framasoft/mobilizon/commits/84fc175))
* Translated using Weblate (Italian) ([5b64388](https://framagit.org/framasoft/mobilizon/commits/5b64388))
* Translated using Weblate (Italian) ([5e3dedb](https://framagit.org/framasoft/mobilizon/commits/5e3dedb))
* Translated using Weblate (Italian) ([afe4dd2](https://framagit.org/framasoft/mobilizon/commits/afe4dd2))
* Translated using Weblate (Italian) ([fa0ae83](https://framagit.org/framasoft/mobilizon/commits/fa0ae83))
* Translated using Weblate (Italian) ([181a5a7](https://framagit.org/framasoft/mobilizon/commits/181a5a7))
* Translated using Weblate (Italian) ([827caa3](https://framagit.org/framasoft/mobilizon/commits/827caa3))
* Translated using Weblate (Italian) ([d08d350](https://framagit.org/framasoft/mobilizon/commits/d08d350))
* Translated using Weblate (Italian) ([e9d38c2](https://framagit.org/framasoft/mobilizon/commits/e9d38c2))
* Translated using Weblate (Italian) ([a4578f3](https://framagit.org/framasoft/mobilizon/commits/a4578f3))
* Translated using Weblate (Polish) ([d62c31e](https://framagit.org/framasoft/mobilizon/commits/d62c31e))
* Translated using Weblate (Polish) ([a8ea217](https://framagit.org/framasoft/mobilizon/commits/a8ea217))
* Translated using Weblate (Polish) ([42537af](https://framagit.org/framasoft/mobilizon/commits/42537af))
* Translated using Weblate (Polish) ([fb0a74e](https://framagit.org/framasoft/mobilizon/commits/fb0a74e))
* Translated using Weblate (Polish) ([2458076](https://framagit.org/framasoft/mobilizon/commits/2458076))
* Translated using Weblate (Polish) ([46ffc8c](https://framagit.org/framasoft/mobilizon/commits/46ffc8c))
* Translated using Weblate (Polish) ([f0d7807](https://framagit.org/framasoft/mobilizon/commits/f0d7807))
* Translated using Weblate (Portuguese (Brazil)) ([9f78c73](https://framagit.org/framasoft/mobilizon/commits/9f78c73))
* Translated using Weblate (Portuguese (Brazil)) ([802ab78](https://framagit.org/framasoft/mobilizon/commits/802ab78))
* Translated using Weblate (Spanish) ([ee5ee8d](https://framagit.org/framasoft/mobilizon/commits/ee5ee8d))
* Translated using Weblate (Spanish) ([66c49e4](https://framagit.org/framasoft/mobilizon/commits/66c49e4))
* Translated using Weblate (Tatar) ([ba5f8f8](https://framagit.org/framasoft/mobilizon/commits/ba5f8f8))
* Update translation files ([9aa9cd2](https://framagit.org/framasoft/mobilizon/commits/9aa9cd2))
* WIP ([b5672ce](https://framagit.org/framasoft/mobilizon/commits/b5672ce))
* build: downgrade Sentry since it doesn't want to compile ([b2bacbf](https://framagit.org/framasoft/mobilizon/commits/b2bacbf))
* build: only run ecto create & migrate & tz_world update on prepare_test task, not main test one ([8d11073](https://framagit.org/framasoft/mobilizon/commits/8d11073))
* build: replace @pluralsh/socket with @framasoft/socket ([435bd9d](https://framagit.org/framasoft/mobilizon/commits/435bd9d))
* build: replace @vueuse/head with @unhead/vue ([5602164](https://framagit.org/framasoft/mobilizon/commits/5602164))
* build: switch from yarn to npm to manage js dependencies and move js contents to root ([2e72f6f](https://framagit.org/framasoft/mobilizon/commits/2e72f6f))
* build(deps): replace absinthe socket library with fork ([ec397aa](https://framagit.org/framasoft/mobilizon/commits/ec397aa))
* build(docker): optimize image size ([f34099d](https://framagit.org/framasoft/mobilizon/commits/f34099d)), closes [#1012](https://framagit.org/framasoft/mobilizon/issues/1012)
* ci: bump node version in CI ([3205512](https://framagit.org/framasoft/mobilizon/commits/3205512))
* ci: fix handling pages deploy with existing public folder ([1228ec1](https://framagit.org/framasoft/mobilizon/commits/1228ec1))
* ci: install python3 instead of python ([5d65981](https://framagit.org/framasoft/mobilizon/commits/5d65981))
* ci: Release on multiple distributions & fix Docker multiple-step build ([262d1fc](https://framagit.org/framasoft/mobilizon/commits/262d1fc))
* test: fix ActivityPub headers test ([f248660](https://framagit.org/framasoft/mobilizon/commits/f248660))
* test: fix front-end tests ([105d3b5](https://framagit.org/framasoft/mobilizon/commits/105d3b5))
* test: fix histoire configuration ([bfbc299](https://framagit.org/framasoft/mobilizon/commits/bfbc299))
* test: fix tests ([c731f0f](https://framagit.org/framasoft/mobilizon/commits/c731f0f))
* test: fix unit backend tests ([e051df1](https://framagit.org/framasoft/mobilizon/commits/e051df1))
* chore: fix prettier configuration and run it ([c255cea](https://framagit.org/framasoft/mobilizon/commits/c255cea))
* chore: update Sobelow security ignores ([1d0398d](https://framagit.org/framasoft/mobilizon/commits/1d0398d))
* chore: upgrade deps ([99c80c6](https://framagit.org/framasoft/mobilizon/commits/99c80c6))
* chore(deps): update geo_postgis to 3.5.0 for Elixir 1.15 compat ([3936eb4](https://framagit.org/framasoft/mobilizon/commits/3936eb4))
* chore(deps): upgrade dependencies ([3d9beaa](https://framagit.org/framasoft/mobilizon/commits/3d9beaa))
* chore(i18n): add missing translation key ([6ecfa48](https://framagit.org/framasoft/mobilizon/commits/6ecfa48))
* chore(i18n): update gettext dependency and regenerate translation files ([d7ad934](https://framagit.org/framasoft/mobilizon/commits/d7ad934))
* chore(i18n): update translation templates ([70e9ce0](https://framagit.org/framasoft/mobilizon/commits/70e9ce0))
* refactor: use dedicated email for event announcements ([b97f1c9](https://framagit.org/framasoft/mobilizon/commits/b97f1c9))
* docs(dev.md): keep some info about structure ([d130b15](https://framagit.org/framasoft/mobilizon/commits/d130b15))
* feat(export): add event status in iCalendar exports ([7a1bfca](https://framagit.org/framasoft/mobilizon/commits/7a1bfca))
* feat(federation): expose public activities as announcements in relay outbx & rfrsh profile aftr fllw ([85e4715](https://framagit.org/framasoft/mobilizon/commits/85e4715))


## 3.2.0 (2023-09-07)

### Features

* **cli:** allow the mobilizon.users.delete command to delete multiple users by email domain or ip ([bc50ab6](https://framagit.org/framasoft/mobilizon/commit/bc50ab66f3a44df220a7daa3cb1d917bd02487ba))
* **export:** add date of participant creation in participant exports ([fef60ed](https://framagit.org/framasoft/mobilizon/commit/fef60ed0f92fc4e09ee261ff03f1139aff2449c3)), closes [#1343](https://framagit.org/framasoft/mobilizon/issues/1343)
* **notifications:** add missing notifications when an user registers to an event ([da532c7](https://framagit.org/framasoft/mobilizon/commit/da532c7059bea5fcd47e2f42210e8ba842a11d63)), closes [#1344](https://framagit.org/framasoft/mobilizon/issues/1344)
* **reports:** allow reports to hold multiple events ([f2ac3e2](https://framagit.org/framasoft/mobilizon/commit/f2ac3e2e5d28f4257a5e2d4870d339fecf3a5f1b))
* **reports:** allow to suspend a profile or a user account directly from the report view ([69588db](https://framagit.org/framasoft/mobilizon/commit/69588dbf4ce2f80cc5829a841135042fa73eb4fe))
* **reports:** improve reportview and allow removing content + resolve report automatically ([b105c50](https://framagit.org/framasoft/mobilizon/commit/b105c508c03ce3cb96dd8342f96d3291aa197e22))
* **reports:** show suspended status next to reported profile ([b9a165a](https://framagit.org/framasoft/mobilizon/commit/b9a165a7fc565dc583cca81dd9c54570f73b4ca3))
* Add option to link an external registration provider for events ([2de6937](https://framagit.org/framasoft/mobilizon/commit/2de6937407743100daba1d397db4da32d4cb606b))
* **back:** add admin setting to disable external event feature ([f6611e8](https://framagit.org/framasoft/mobilizon/commit/f6611e8eb5a7e12dc0dc0c216b598e04144e07c6))
* improve group creation view [3f601748](https://framagit.org/framasoft/mobilizon/-/commit/3f60174877bbe05773b1d1b2ceb91749adec7ed7)
* **auth:** pre-initialize registration fields with information from 3rd-party provider ([7e49345](https://framagit.org/framasoft/mobilizon/commit/7e4934513a0ca4a5f95e8c8e4a600459911899d5)), closes [#1105](https://framagit.org/framasoft/mobilizon/issues/1105)


### Bug Fixes

* add inets and ssl to extra_applications in test env ([af46bea](https://framagit.org/framasoft/mobilizon/commit/af46bea7f730f4479bb31518a9fa53de7302049a))
* **apps:** add missing app scopes ([7e98097](https://framagit.org/framasoft/mobilizon/commit/7e98097c710663609274200564fca9eff1ea4d20))
* **apps:** make sure we can set status for an application token ([1a6095d](https://framagit.org/framasoft/mobilizon/commit/1a6095d27aeb440379d27c3894c302f831214822))
* **backend:** fix config cache not being used everytime ([ed3cd58](https://framagit.org/framasoft/mobilizon/commit/ed3cd5858cd27a90d4724a95ee660bbc08e92e80))
* **backend:** handle email not being sent when resending registration instructions ([b2492a3](https://framagit.org/framasoft/mobilizon/commit/b2492a387086528598da36f11e53569c5bdb164c))
* create event time/date allignment ([3de90a3](https://framagit.org/framasoft/mobilizon/commit/3de90a3c73414105becdcb24899016178b1c6f02))
* **docker:** fix Qemu segfaulting on arm64 ([8e3f90f](https://framagit.org/framasoft/mobilizon/commit/8e3f90f7135e2a8a8ac46464420c9d57b2e02534)), closes [#1241](https://framagit.org/framasoft/mobilizon/issues/1241) [#1249](https://framagit.org/framasoft/mobilizon/issues/1249)
* **federation:** fix getting pictures from Gruppe actors ([7c5f8b2](https://framagit.org/framasoft/mobilizon/commit/7c5f8b24311253ef89c7e47cd7ce22ebe6cf2ec9))
* fix Elixir 1.15 depreciations ([da70427](https://framagit.org/framasoft/mobilizon/commit/da70427e3292be8943167bbad73d5a782a98c6b5))
* fix some typescript issues with pwa ([e351d3c](https://framagit.org/framasoft/mobilizon/commit/e351d3cb2f8183bb4335b3b21e154f46d9237a76))
* **front:** avoid crashing if we don't have configuration data in time when in guard ([7916261](https://framagit.org/framasoft/mobilizon/commit/7916261c5c8c680d064fba106619d733575bc39c))
* **front:** fix alignment of some input elements on event edition form ([50695fc](https://framagit.org/framasoft/mobilizon/commit/50695fcfd5e0dc6fd55185f4399d45ed1852f880))
* **front:** fix changing language not being saved to the user's settings ([010a5e4](https://framagit.org/framasoft/mobilizon/commit/010a5e426def0a0b7f2658234f3c9d6eec46a68e))
* **front:** fix comment not showing up when replying in a discussion ([cc8f02d](https://framagit.org/framasoft/mobilizon/commit/cc8f02d0a6354c49437e7ff1780912a71bed03f4))
* **front:** fix confirm anonymous participation ([f99267c](https://framagit.org/framasoft/mobilizon/commit/f99267c6115601fce6eadd6ee54893fde0d6fd84))
* **front:** fix discussion edition panel always showing up ([fee0e38](https://framagit.org/framasoft/mobilizon/commit/fee0e388af798f14d4da8cbd9f037137f6be9f85))
* **front:** fix display of participants list ([c6b83c4](https://framagit.org/framasoft/mobilizon/commit/c6b83c42d6fbb2e6a93175479ef1620913c6532f))
* **front:** fix map ([8f84ba1](https://framagit.org/framasoft/mobilizon/commit/8f84ba1d08ce8d2d266010ee3166106eed66116d)), closes [#1314](https://framagit.org/framasoft/mobilizon/issues/1314)
* **front:** fix missing type causing eslint error ([c76dba3](https://framagit.org/framasoft/mobilizon/commit/c76dba3dbfe4fb0ab9ed24f71a6f64681c643fca))
* **front:** fix selecting all participants in participant view ([beef3ff](https://framagit.org/framasoft/mobilizon/commit/beef3ff16d12f5d5710e302b739dd724ad4b0cb5))
* **front:** fix showing error message when app to approve doesn't exist ([12cbff1](https://framagit.org/framasoft/mobilizon/commit/12cbff154ae5cdd72a1a7e882cb99e943010222b))
* **front:** fix some alignment of some UI elements in mobile event view ([8c313b5](https://framagit.org/framasoft/mobilizon/commit/8c313b53977493792c113b5191443515f8aeae78))
* **front:** properly handle error when approving app ([086d208](https://framagit.org/framasoft/mobilizon/commit/086d208ee50ae1f9ecb30196e758fdc7687714ae))
* **front:** properly handle post not found ([8db31c9](https://framagit.org/framasoft/mobilizon/commit/8db31c99df668389db4c6651fa71a8c1420484cf))
* **front:** reduce horizontal padding on main element ([f3c218f](https://framagit.org/framasoft/mobilizon/commit/f3c218f841292a28ec6d1284a205e2c7fd7d8f6e))
* **lint:** fix lint after upgrades ([60aceb4](https://framagit.org/framasoft/mobilizon/commit/60aceb442ae49458e31a1f38d277eca7af248a36))
* **mail:** fix sending mail on OTP26 ([f54fff5](https://framagit.org/framasoft/mobilizon/commit/f54fff56fc5c94408b1fd16b1eb9dd0f91bc2dfd)), closes [#1341](https://framagit.org/framasoft/mobilizon/issues/1341)
* **push:** fix push subscriptions registration ([fdf87ea](https://framagit.org/framasoft/mobilizon/commit/fdf87ea991b1d406b28dbd0c8807908939070c8b))
* **pwa:** improvements to the PWA configuration ([04c5ac1](https://framagit.org/framasoft/mobilizon/commit/04c5ac11636a4ffb5d3ac0c510b028edfb7fc057))
* **reports:** make front-end handle nullified reported_id and reported_id ([afd2ffe](https://framagit.org/framasoft/mobilizon/commit/afd2ffe72294baedc9dd15dc89d57301831545cc))
* **reports:** remove on delete cascade for reports ([4f530ca](https://framagit.org/framasoft/mobilizon/commit/4f530cabcf1bcadc09399a728975d329f3c9fdbf))
* **front:** fix behavior of local toggle for profiles & groups view depending on domain value ([84f62cd](https://framagit.org/framasoft/mobilizon/commit/84f62cd043d5cf5d186fea6f24a1a9dff5fc64ce))
* **i18n:** add missing translations ([af670f3](https://framagit.org/framasoft/mobilizon/commit/af670f39478b11465205fbea9b9268bab401bbb6))
* **back:** allow any other type of actor to be suspended ([92b222b](https://framagit.org/framasoft/mobilizon/commit/92b222b091cf6248969b0206e7c052b725a1286b))
* **back:** only try to insert activities for groups ([cfc9843](https://framagit.org/framasoft/mobilizon/commit/cfc984345e90b2960077956858606395f37ef9b9))
* **front:** don't return promise if result is not finished loading for tags ([8c14ba4](https://framagit.org/framasoft/mobilizon/commit/8c14ba441c6f0fadb3c59f80ff4e3abb2e625752))
* **front:** fix getting result from interactable object in InteractView ([31b2d06](https://framagit.org/framasoft/mobilizon/commit/31b2d065a904453580731133cd3dfd545a5816fa))
* **docker:** make Docker entrypoint port configurable via $MOBILIZON_DATABASE_PORT ([13099e0](https://framagit.org/framasoft/mobilizon/commit/13099e0f118b727a1472282c6419ef9b1842c191))
* **front:** fix fetching and rendering profile mentions and fetching tags ([895378a](https://framagit.org/framasoft/mobilizon/commit/895378a96bf8a6c7662ed02509c37b8d8a95db0b))
* **sitemap:** save generated sitemaps in configurable directory ([f28109a](https://framagit.org/framasoft/mobilizon/commit/f28109ad50d85143e38c8e9f5d09c28f80566462)), closes [#1321](https://framagit.org/framasoft/mobilizon/issues/1321)
* **auth:** small front fixes in 3rd-party auth provider callback ([bde7206](https://framagit.org/framasoft/mobilizon/commit/bde7206a1ca44fdf96d817921bb1efc497dcae40))
* **config:** rollback Mailer tls setting to :never by default ([3d63c12](https://framagit.org/framasoft/mobilizon/commit/3d63c12e88ca31f582489f126d1ef5677af79721))
* **docker:** fix entrypoint PostgreSQL extensions creations not using MOBILIZON_DATABASE_PORT ([9b49918](https://framagit.org/framasoft/mobilizon/commit/9b4991844ecaf7c1f1287ae62d1dfd463c2ea26b)), closes [#1321](https://framagit.org/framasoft/mobilizon/issues/1321) [#1321](https://framagit.org/framasoft/mobilizon/issues/1321)
* **front:** fixes in EditIdentity view ([7e13e2b](https://framagit.org/framasoft/mobilizon/commit/7e13e2baa7690d5dfc4a8b12097a4ed85ea825d7))


## 3.2.0-beta.5 (2023-09-06)

### Bug Fixes

* **docker:** make Docker entrypoint port configurable via $MOBILIZON_DATABASE_PORT ([13099e0](https://framagit.org/framasoft/mobilizon/commit/13099e0f118b727a1472282c6419ef9b1842c191))
* **front:** fix fetching and rendering profile mentions and fetching tags ([895378a](https://framagit.org/framasoft/mobilizon/commit/895378a96bf8a6c7662ed02509c37b8d8a95db0b))
* **sitemap:** save generated sitemaps in configurable directory ([f28109a](https://framagit.org/framasoft/mobilizon/commit/f28109ad50d85143e38c8e9f5d09c28f80566462)), closes [#1321](https://framagit.org/framasoft/mobilizon/issues/1321)


## 3.2.0-beta.4  (2023-09-05)

### Bug Fixes

* **back:** allow any other type of actor to be suspended ([92b222b](https://framagit.org/framasoft/mobilizon/commit/92b222b091cf6248969b0206e7c052b725a1286b))
* **back:** only try to insert activities for groups ([cfc9843](https://framagit.org/framasoft/mobilizon/commit/cfc984345e90b2960077956858606395f37ef9b9))
* **front:** don't return promise if result is not finished loading for tags ([8c14ba4](https://framagit.org/framasoft/mobilizon/commit/8c14ba441c6f0fadb3c59f80ff4e3abb2e625752))
* **front:** fix getting result from interactable object in InteractView ([31b2d06](https://framagit.org/framasoft/mobilizon/commit/31b2d065a904453580731133cd3dfd545a5816fa))


## 3.2.0-beta.3  (2023-09-04)

### Bug Fixes

* **i18n:** add missing translations ([af670f3](https://framagit.org/framasoft/mobilizon/commit/af670f39478b11465205fbea9b9268bab401bbb6))


### Features

* Add option to link an external registration provider for events ([2de6937](https://framagit.org/framasoft/mobilizon/commit/2de6937407743100daba1d397db4da32d4cb606b))
* **back:** add admin setting to disable external event feature ([f6611e8](https://framagit.org/framasoft/mobilizon/commit/f6611e8eb5a7e12dc0dc0c216b598e04144e07c6))
* improve group creation view [3f601748](https://framagit.org/framasoft/mobilizon/-/commit/3f60174877bbe05773b1d1b2ceb91749adec7ed7)


## 3.2.0-beta.2  (2023-09-01)

Fixes a CI issue that prevented 3.2.0-beta.2 being released.

### Bug Fixes

* **front:** fix behavior of local toggle for profiles & groups view depending on domain value ([84f62cd](https://framagit.org/framasoft/mobilizon/commit/84f62cd043d5cf5d186fea6f24a1a9dff5fc64ce))


## 3.2.0-beta.1  (2023-09-01)

### Features

* **cli:** allow the mobilizon.users.delete command to delete multiple users by email domain or ip ([bc50ab6](https://framagit.org/framasoft/mobilizon/commit/bc50ab66f3a44df220a7daa3cb1d917bd02487ba))
* **export:** add date of participant creation in participant exports ([fef60ed](https://framagit.org/framasoft/mobilizon/commit/fef60ed0f92fc4e09ee261ff03f1139aff2449c3)), closes [#1343](https://framagit.org/framasoft/mobilizon/issues/1343)
* **notifications:** add missing notifications when an user registers to an event ([da532c7](https://framagit.org/framasoft/mobilizon/commit/da532c7059bea5fcd47e2f42210e8ba842a11d63)), closes [#1344](https://framagit.org/framasoft/mobilizon/issues/1344)
* **reports:** allow reports to hold multiple events ([f2ac3e2](https://framagit.org/framasoft/mobilizon/commit/f2ac3e2e5d28f4257a5e2d4870d339fecf3a5f1b))
* **reports:** allow to suspend a profile or a user account directly from the report view ([69588db](https://framagit.org/framasoft/mobilizon/commit/69588dbf4ce2f80cc5829a841135042fa73eb4fe))
* **reports:** improve reportview and allow removing content + resolve report automatically ([b105c50](https://framagit.org/framasoft/mobilizon/commit/b105c508c03ce3cb96dd8342f96d3291aa197e22))
* **reports:** show suspended status next to reported profile ([b9a165a](https://framagit.org/framasoft/mobilizon/commit/b9a165a7fc565dc583cca81dd9c54570f73b4ca3))


### Bug Fixes

* add inets and ssl to extra_applications in test env ([af46bea](https://framagit.org/framasoft/mobilizon/commit/af46bea7f730f4479bb31518a9fa53de7302049a))
* **apps:** add missing app scopes ([7e98097](https://framagit.org/framasoft/mobilizon/commit/7e98097c710663609274200564fca9eff1ea4d20))
* **apps:** make sure we can set status for an application token ([1a6095d](https://framagit.org/framasoft/mobilizon/commit/1a6095d27aeb440379d27c3894c302f831214822))
* **backend:** fix config cache not being used everytime ([ed3cd58](https://framagit.org/framasoft/mobilizon/commit/ed3cd5858cd27a90d4724a95ee660bbc08e92e80))
* **backend:** handle email not being sent when resending registration instructions ([b2492a3](https://framagit.org/framasoft/mobilizon/commit/b2492a387086528598da36f11e53569c5bdb164c))
* create event time/date allignment ([3de90a3](https://framagit.org/framasoft/mobilizon/commit/3de90a3c73414105becdcb24899016178b1c6f02))
* **docker:** fix Qemu segfaulting on arm64 ([8e3f90f](https://framagit.org/framasoft/mobilizon/commit/8e3f90f7135e2a8a8ac46464420c9d57b2e02534)), closes [#1241](https://framagit.org/framasoft/mobilizon/issues/1241) [#1249](https://framagit.org/framasoft/mobilizon/issues/1249)
* **federation:** fix getting pictures from Gruppe actors ([7c5f8b2](https://framagit.org/framasoft/mobilizon/commit/7c5f8b24311253ef89c7e47cd7ce22ebe6cf2ec9))
* fix Elixir 1.15 depreciations ([da70427](https://framagit.org/framasoft/mobilizon/commit/da70427e3292be8943167bbad73d5a782a98c6b5))
* fix some typescript issues with pwa ([e351d3c](https://framagit.org/framasoft/mobilizon/commit/e351d3cb2f8183bb4335b3b21e154f46d9237a76))
* **front:** avoid crashing if we don't have configuration data in time when in guard ([7916261](https://framagit.org/framasoft/mobilizon/commit/7916261c5c8c680d064fba106619d733575bc39c))
* **front:** fix alignment of some input elements on event edition form ([50695fc](https://framagit.org/framasoft/mobilizon/commit/50695fcfd5e0dc6fd55185f4399d45ed1852f880))
* **front:** fix changing language not being saved to the user's settings ([010a5e4](https://framagit.org/framasoft/mobilizon/commit/010a5e426def0a0b7f2658234f3c9d6eec46a68e))
* **front:** fix comment not showing up when replying in a discussion ([cc8f02d](https://framagit.org/framasoft/mobilizon/commit/cc8f02d0a6354c49437e7ff1780912a71bed03f4))
* **front:** fix confirm anonymous participation ([f99267c](https://framagit.org/framasoft/mobilizon/commit/f99267c6115601fce6eadd6ee54893fde0d6fd84))
* **front:** fix discussion edition panel always showing up ([fee0e38](https://framagit.org/framasoft/mobilizon/commit/fee0e388af798f14d4da8cbd9f037137f6be9f85))
* **front:** fix display of participants list ([c6b83c4](https://framagit.org/framasoft/mobilizon/commit/c6b83c42d6fbb2e6a93175479ef1620913c6532f))
* **front:** fix map ([8f84ba1](https://framagit.org/framasoft/mobilizon/commit/8f84ba1d08ce8d2d266010ee3166106eed66116d)), closes [#1314](https://framagit.org/framasoft/mobilizon/issues/1314)
* **front:** fix missing type causing eslint error ([c76dba3](https://framagit.org/framasoft/mobilizon/commit/c76dba3dbfe4fb0ab9ed24f71a6f64681c643fca))
* **front:** fix selecting all participants in participant view ([beef3ff](https://framagit.org/framasoft/mobilizon/commit/beef3ff16d12f5d5710e302b739dd724ad4b0cb5))
* **front:** fix showing error message when app to approve doesn't exist ([12cbff1](https://framagit.org/framasoft/mobilizon/commit/12cbff154ae5cdd72a1a7e882cb99e943010222b))
* **front:** fix some alignment of some UI elements in mobile event view ([8c313b5](https://framagit.org/framasoft/mobilizon/commit/8c313b53977493792c113b5191443515f8aeae78))
* **front:** properly handle error when approving app ([086d208](https://framagit.org/framasoft/mobilizon/commit/086d208ee50ae1f9ecb30196e758fdc7687714ae))
* **front:** properly handle post not found ([8db31c9](https://framagit.org/framasoft/mobilizon/commit/8db31c99df668389db4c6651fa71a8c1420484cf))
* **front:** reduce horizontal padding on main element ([f3c218f](https://framagit.org/framasoft/mobilizon/commit/f3c218f841292a28ec6d1284a205e2c7fd7d8f6e))
* **lint:** fix lint after upgrades ([60aceb4](https://framagit.org/framasoft/mobilizon/commit/60aceb442ae49458e31a1f38d277eca7af248a36))
* **mail:** fix sending mail on OTP26 ([f54fff5](https://framagit.org/framasoft/mobilizon/commit/f54fff56fc5c94408b1fd16b1eb9dd0f91bc2dfd)), closes [#1341](https://framagit.org/framasoft/mobilizon/issues/1341)
* **push:** fix push subscriptions registration ([fdf87ea](https://framagit.org/framasoft/mobilizon/commit/fdf87ea991b1d406b28dbd0c8807908939070c8b))
* **pwa:** improvements to the PWA configuration ([04c5ac1](https://framagit.org/framasoft/mobilizon/commit/04c5ac11636a4ffb5d3ac0c510b028edfb7fc057))
* **reports:** make front-end handle nullified reported_id and reported_id ([afd2ffe](https://framagit.org/framasoft/mobilizon/commit/afd2ffe72294baedc9dd15dc89d57301831545cc))
* **reports:** remove on delete cascade for reports ([4f530ca](https://framagit.org/framasoft/mobilizon/commit/4f530cabcf1bcadc09399a728975d329f3c9fdbf))


## 3.1.3 (2023-06-21)

### Bug Fixes

* **groups:** fix unauthenticated access to groups because of missing read:group:members permission ([3714925](https://framagit.org/framasoft/mobilizon/commit/3714925896ad0415496352b9901ebec199afa0f2)), closes [#1311](https://framagit.org/framasoft/mobilizon/issues/1311)


## 3.1.2  (2023-06-21)

### Bug Fixes

* **activity settings:** fix saving activity settings ([6c1e1e9](https://framagit.org/framasoft/mobilizon/commit/6c1e1e98d81c7469f41beed17cfa1d4b718b5d13)), closes [#1251](https://framagit.org/framasoft/mobilizon/issues/1251)
* **apps:** fix pruning old application device activations ([dd00620](https://framagit.org/framasoft/mobilizon/commit/dd00620b9a54b2b1356855d280e03c82befe15e4))
* **backend:** filter out nil tags before starting looking for existing ones ([f04d2b9](https://framagit.org/framasoft/mobilizon/commit/f04d2b9225b80333f03a3cc9366df4a05af88a73))
* **deps:** fix compatibility with elixir-plug/mime 2.0.5 ([d63999c](https://framagit.org/framasoft/mobilizon/commit/d63999c081bcbb5923af17b71edbfd13a3720d7d))
* **discussions:** handle changeset errors when updating discussion ([ca06ec3](https://framagit.org/framasoft/mobilizon/commit/ca06ec397fbd6848e340dfae12c635736069a9f3))
* **exports:** properly handle export format not being handled ([a76b1ca](https://framagit.org/framasoft/mobilizon/commit/a76b1ca66d776fbe4566d7f23b38b087ae32530b))
* **federation:** allow federated usernames with capitals ([d502164](https://framagit.org/framasoft/mobilizon/commit/d5021647d753e6457e459b1f992da60876292428))
* **federation:** handle fetch_actor with a map ([552ab4c](https://framagit.org/framasoft/mobilizon/commit/552ab4c80b2f99095028ab3685c71ff9efdb94eb))
* **federation:** handle string values for tags when constructing mentions ([2729d5e](https://framagit.org/framasoft/mobilizon/commit/2729d5ed7acef7c20a4388f019152e80a9db163c))
* **federation:** ignore mentions from everything that's not a AP Person ([56f341e](https://framagit.org/framasoft/mobilizon/commit/56f341e960b7ae0a5fe78d7174f0e05d14add3f2))
* **federation:** only refresh instances once a day ([6745590](https://framagit.org/framasoft/mobilizon/commit/6745590e54dce236dc7a2319f9c49c4aa6858306))
* **federation:** prevent fetching own relay actor ([b981f91](https://framagit.org/framasoft/mobilizon/commit/b981f91cf748079847ae7a71b68f98b6914c951f))
* **federation:** restrict fetch_group first arg to binaries ([e8d34b4](https://framagit.org/framasoft/mobilizon/commit/e8d34b4ea9f06d16a5982da8e5ff5140852c985d))
* **federation:** rotate relay keys on startup if missing private keys ([5381eaa](https://framagit.org/framasoft/mobilizon/commit/5381eaae22248cdc6585d19c10be7fe2b7f5709f))
* **front:** add missing title to Participants View page ([a5a86a5](https://framagit.org/framasoft/mobilizon/commit/a5a86a5e1be08cf9123ee7ad0979974bc2be1cb4))
* **front:** fix displaying user activity settings checkboxes ([8e21c30](https://framagit.org/framasoft/mobilizon/commit/8e21c30f92f47dcb742d8f7df2aed59191158d80)), closes [#1251](https://framagit.org/framasoft/mobilizon/issues/1251)
* **front:** fix wrong key name for dialog.confirm() option ([c8f49e1](https://framagit.org/framasoft/mobilizon/commit/c8f49e1837d719cd737c3e1ae976f14b20345e2b))
* **front:** fix wrong value for timezone when it has no prefix ([2dd0e13](https://framagit.org/framasoft/mobilizon/commit/2dd0e13eba8bb5c04af45bae0de059deb93c2efa)), closes [#1275](https://framagit.org/framasoft/mobilizon/issues/1275)
* **group:** fix getting group members count ([f749518](https://framagit.org/framasoft/mobilizon/commit/f749518bf7a29a86da559bfe6aba6d7485e7cfeb)), closes [#1303](https://framagit.org/framasoft/mobilizon/issues/1303)
* **participant exports:** fix participants by returning the export type as well as the file path ([49b04c9](https://framagit.org/framasoft/mobilizon/commit/49b04c9b19517daa0a07656779d53001b39ab803))
* **participant:** handle re-confirming participation ([5cc5c99](https://framagit.org/framasoft/mobilizon/commit/5cc5c9943cbc9a53246dda98958e99d004f0dfa9))

### Features

* **graphql:** validate timezone id as a GraphQL Scalar ([845bb6a](https://framagit.org/framasoft/mobilizon/commit/845bb6ac90081ef8cb4cff8d6ec3d11bfc19857c)), closes [#1299](https://framagit.org/framasoft/mobilizon/issues/1299)


## 3.1.1 (2023-06-02)

### Features

* **anti-spam:** allow to only scan for spam in profiles or events ([c971287](https://framagit.org/framasoft/mobilizon/-/commit/c971287624913c8555fe288af0df1175701e6209))

### Bug Fixes

* **front:** fix group settings getting unresponsive because of reactive bug ([f1e119c](https://framagit.org/framasoft/mobilizon/-/commit/f1e119cb7ad580dfab73de3083f20a7303822888)), closes [#1298](https://framagit.org/framasoft/mobilizon/-/issues/1298)
* **search:** fix global search sorting ([39e24c3](https://framagit.org/framasoft/mobilizon/-/commit/39e24c328a21f7058e4d2526e13eae85e39bae86)), closes [#1297](https://framagit.org/framasoft/mobilizon/-/issues/1297)

## 3.1.0 (2023-05-31)

### Features

* **API:** Allow to create apps, with permissions and both Authorization Code Flow and Device Flow
* **addresses:** Allow to enter manual addresses ([85d643d](https://framagit.org/framasoft/mobilizon/-/commit/85d643d0ecd5e7504f32953b9ed1509697b915e2))
* **docker:** Specify the folder where tzdata downloads data so that it can be used in a volume ([4bb0625](https://framagit.org/framasoft/mobilizon/-/commit/4bb062528f12be530a3754ca23c1bc6dbc862e5a)), closes [#1280](https://framagit.org/framasoft/mobilizon/-/issues/1280)
* **spam:** Introduce checking new accounts, events & comments for spam with the help of Akismet ([317a343](https://framagit.org/framasoft/mobilizon/-/commit/317a3434b221a1a91b66d8443984269404863a8e))
* **rate-limiting:** Introduce rate-limiting on some endpoints ([c07ba3a5](https://framagit.org/framasoft/mobilizon/-/commit/c07ba3a5d19c419ef8aaf3ea9ca6e7f48e4f4487))
* **front:** improve padding on event tags ([7fa452d](https://framagit.org/framasoft/mobilizon/-/commit/7fa452d9e3f9bb2443e571c9a32eaed51e32480a))
* **front:** make admin profile view linkable directly with parameters ([08ce7e2](https://framagit.org/framasoft/mobilizon/-/commit/08ce7e26b73045279261ab87a14cb4f3dab5df1e))
* **front:** make profile members link to profile on group admin view and the reverse ([96129d2](https://framagit.org/framasoft/mobilizon/-/commit/96129d2339133027220d3b5fcb1c52f84bcc5cbb))
* **front:** make profiles and group admin views default to local ([3e0324d](https://framagit.org/framasoft/mobilizon/-/commit/3e0324d36ec5a8aa388e6b5d598a6f9a0c596797))
* **front:** redirect user to homepage on disconnect when currently on private page ([d5a6df9](https://framagit.org/framasoft/mobilizon/-/commit/d5a6df9940fb458c5dbaee149015c02ebc370c6b)), closes [#1278](https://framagit.org/framasoft/mobilizon/-/issues/1278)
* **front:** show skeleton content on event view until the event is loaded ([dc3b93f](https://framagit.org/framasoft/mobilizon/-/commit/dc3b93ffb5a4b072aec792533fd6e4b58ed7a893))
* **i18n:** activate croatian language ([94182ae](https://framagit.org/framasoft/mobilizon/-/commit/94182aed2d8a22d00534f6376dfda2658bc8ba7e))
* **i18n:** activate japanese language ([6bd8034](https://framagit.org/framasoft/mobilizon/-/commit/6bd8034fe816a432c3547de6d1ad8a18e73dc314)), closes [#1293](https://framagit.org/framasoft/mobilizon/-/issues/1293)
* **post:** show post visibily in PostListItem component ([ec7ca4d](https://framagit.org/framasoft/mobilizon/-/commit/ec7ca4ddf18a38cf6f51d38b540eecc9858f3c98))

### Bug Fixes

* **global-search:** Add option values in debug log before calling global search service ([8141bb0](https://framagit.org/framasoft/mobilizon/-/commit/8141bb0acbc4eb02a917c5bc18712d0d954c4ee5))
* **apps:** Fix cleaning application data background job ([aa20f69](https://framagit.org/framasoft/mobilizon/-/commit/aa20f6991127ddee546fc0b867298c1342dbcb4d))
* **apps:** Show message when the user doesn't have approved apps yet ([e0ee9c1](https://framagit.org/framasoft/mobilizon/-/commit/e0ee9c143b0335753db5dfae19e324781d55bd4e))
* **auth:** Handle logging-in with disabled auth provider ([a22a5e3](https://framagit.org/framasoft/mobilizon/-/commit/a22a5e3cb924869e32cb9ed71dab3e03d91c018f))
* **backend:** Fix Mobilizon.Events.list_participations_for_user_query/1 ([bcf6fd8](https://framagit.org/framasoft/mobilizon/-/commit/bcf6fd893c762c12b63d7e02da43cd5c05db509b))
* **backend:** Handle CLDR data having no standard property for a language ([dbe2da7](https://framagit.org/framasoft/mobilizon/-/commit/dbe2da79c3aa1543b87dce61b5fd90195fb53afe))
* **backend:** Ignore group mentions for now ([b5f106b](https://framagit.org/framasoft/mobilizon/-/commit/b5f106b0a81fefba3203f8ec5855e834a2078222))
* **back:** Improve error message when requesting reset passwords and new instructions ([1c1d0d4](https://framagit.org/framasoft/mobilizon/-/commit/1c1d0d47d70cf19abe5be42e7ec3a73656a8172b))
* **back:** Replace NaiveDateTime uses with DateTime for consistency ([8ea00e7](https://framagit.org/framasoft/mobilizon/-/commit/8ea00e7c1827ce3056ae51968a62fb3dc03ac6eb))
* **back:** Various small fixes in backend ([2a57340](https://framagit.org/framasoft/mobilizon/-/commit/2a57340a82e414e69924ad89e8db9fc326742cc7))
* bind pagination current prop ([4bcf572](https://framagit.org/framasoft/mobilizon/-/commit/4bcf572c54d904587d0409e2eb68b4ca6cf48fec))
* **federation:** Account suspension should use actor in question as author and not relay actor ([79b48da](https://framagit.org/framasoft/mobilizon/-/commit/79b48da22209a8b2f1b234b8b8e121543a39b22b))
* **feeds:** Only provide future events in ICS/Atom feeds ([f3a4431](https://framagit.org/framasoft/mobilizon/-/commit/f3a443138a0e1e6cf34fc593f5c174d56c21e904)), closes [#1246](https://framagit.org/framasoft/mobilizon/-/issues/1246)
* Fix type of variable in navbar ([50ab531](https://framagit.org/framasoft/mobilizon/-/commit/50ab531156214f883cb03f785ccf65e3f19ef50e))
* **follow-instances:** Show correct error message when trying to follow already following actor ([d969c66](https://framagit.org/framasoft/mobilizon/-/commit/d969c6648f15e1ed280169a4c55d612bb002f03f))
* **front:** Fix about sections titles ([487f406](https://framagit.org/framasoft/mobilizon/-/commit/487f4069b14fde6304c9a42cec5b1c1af79814c5))
* **front:** Fix autocomplete attribute in o-inputitems after Oruga new version BC ([d2ba732](https://framagit.org/framasoft/mobilizon/-/commit/d2ba732b8b51986b739f6fbe3d74fa68e4b74ba0))
* **front:** Fix behaviour when deleting an event from event list ([cfd10ea](https://framagit.org/framasoft/mobilizon/-/commit/cfd10ea96078f03ad3b4f5682e37078ffae16ee4))
* **front:** Fix event list month order ([63c9ed6](https://framagit.org/framasoft/mobilizon/-/commit/63c9ed62de94d6d150798c949bad3d8a2dd4db23)), closes [#1244](https://framagit.org/framasoft/mobilizon/-/issues/1244)
* **front:** Fix instances list pagination ([8543204](https://framagit.org/framasoft/mobilizon/-/commit/8543204bd95de886d8d35bd491f23ecbc0a6ef8d)), closes [#1277](https://framagit.org/framasoft/mobilizon/-/issues/1277)
* **front:** Fix pagination display on dark mode ([4375438](https://framagit.org/framasoft/mobilizon/-/commit/4375438dc9fd2f1c5c9d7ed6670dde04f2da520f))
* **front:** Fix style of My Events participations ([35b07dc](https://framagit.org/framasoft/mobilizon/-/commit/35b07dceaa41c74c28ea49655b755e341f56df32))
* **front:** Focus report comment input in report modal ([2c28312](https://framagit.org/framasoft/mobilizon/-/commit/2c28312fc957901b86c2f3d1db8fc3376f505d37)), closes [#1236](https://framagit.org/framasoft/mobilizon/-/issues/1236)
* **front:** Handle "Failed to fetch dynamically imported module" errors by refreshing the page ([3d21a06](https://framagit.org/framasoft/mobilizon/-/commit/3d21a067897e4aa24f6404686ca6896044584796))
* **front:** Improve Delete account modal UI ([c420bbc](https://framagit.org/framasoft/mobilizon/-/commit/c420bbccc9bd1c348e41904e826dc49c71d7eeb4))
* **front:** Improve resend inscription instructions view and show error when appropriate ([5563052](https://framagit.org/framasoft/mobilizon/-/commit/55630527957d4f6a2e1e6845e64a92bc4794efc8))
* **front:** No cache-only for config ([8dcb76c](https://framagit.org/framasoft/mobilizon/-/commit/8dcb76c30d4fa835837fd3b3833f83682fbae615))
* **front:** Small UI fixes on identity pickers ([6faafd6](https://framagit.org/framasoft/mobilizon/-/commit/6faafd639303e4b57ed81db2ffb5db4ad598b904))
* **i18n:** Update translations ([3b7dbcd](https://framagit.org/framasoft/mobilizon/-/commit/3b7dbcd71f0d19d5e723a03c56ca0b1abbd16f5d))
* **map:** Fix style of the map marker ([c7b90cd](https://framagit.org/framasoft/mobilizon/-/commit/c7b90cd60a14abea7aebab7e1d87f37a44371f7c))
* **map:** Only show map details when needed ([23b5e59](https://framagit.org/framasoft/mobilizon/-/commit/23b5e5930cb9bdb57b1d7fa3ec899d7e4d3571be))
* **map:** Only show marker if we have it's position ([f0cc5ff](https://framagit.org/framasoft/mobilizon/-/commit/f0cc5ffb8feb2f4d70416792a8ab2f4f44bfba85))
* **password-reset:** Lower time before being available to reset password or resend instructions ([73eb460](https://framagit.org/framasoft/mobilizon/-/commit/73eb4603b185c341b63481ed934f66e19aa0784f))
* **search:** Fix event search order ([a4e7ee3](https://framagit.org/framasoft/mobilizon/-/commit/a4e7ee37bedc63b2193a401c801b3b1298f566d2))
* **typespec:** Fix missing return type in typespec ([2043c98](https://framagit.org/framasoft/mobilizon/-/commit/2043c98717e8621b3953d347be0b4a35f494af98))
* Change the way preferredUsername is synced ([a73e5a08](https://framagit.org/framasoft/mobilizon/-/commit/a73e5a085ef48a88dbb8f9c407df0430ca89fe1f))
* datetimepicker: change colors for day & time selectors on dark mode ([b18e8fd3](https://framagit.org/framasoft/mobilizon/-/commit/b18e8fd37c76190ca7f6db82e408cdb005d1810a))
* Save IP and login date from directly registered accounts ([1db5c4ae](https://framagit.org/framasoft/mobilizon/-/commit/1db5c4ae2d49d5adbda2c0825ee0320322b525d6))
* Make sure every cache is properly cleared when managing an event ([f531c39b](https://framagit.org/framasoft/mobilizon/-/commit/f531c39b7e8829a5e3ff68f624b04e12266f2148))
* Add page title for Categories view ([0775814e](https://framagit.org/framasoft/mobilizon/-/commit/0775814e19e6f6ddde564f7a29ae80fab2175d3f))
* Fix notifications settings not working ([31fd99bd](https://framagit.org/framasoft/mobilizon/-/commit/31fd99bd3760872e452351b33765d25b2b9720f2))
* **discussionlistitem:** remove unecessary parameter in vue router target ([779812c](https://framagit.org/framasoft/mobilizon/-/commit/779812c746cf722dd86bcc0ad3bc58e558c13223))
* **emails:** make sure group notification emails are only sent once per email ([927e95f](https://framagit.org/framasoft/mobilizon/-/commit/927e95f387653c7d620e9051c30843ba49c2d65c))
* **frontend:** event edition UI improvements ([0e14a36](https://framagit.org/framasoft/mobilizon/-/commit/0e14a36c6d30ebe386b2136d29539f3b3e914efc))
* **frontend:** only show map on event edition when we have an address or we want to put in details ([02867e6](https://framagit.org/framasoft/mobilizon/-/commit/02867e6e1482ac8770f94fd2bd00174bb31fbdc7))
* **front:** fix showing current group avatar & banners ([20b4aaa](https://framagit.org/framasoft/mobilizon/-/commit/20b4aaabc97080e85cb68fd03393379c7ef82d95))
* **front:** fix showing current identity avatar & banners ([d0f4721](https://framagit.org/framasoft/mobilizon/-/commit/d0f4721925d0c50340d6db8a4e9f4d3e4ca01457))
* **front:** improve UI of the glossary page ([d47b69d](https://framagit.org/framasoft/mobilizon/-/commit/d47b69d6caa7c4405ab2e573ba407f9b2450c3bb))
* **front:** increase padding next to arrow down in `<select>` elements ([94f186c](https://framagit.org/framasoft/mobilizon/-/commit/94f186ce5080316cd633e0344651b0050c2f14d4))
* **front:** remove cache-only for ABOUT GraphQL details on homepage ([6858bcb](https://framagit.org/framasoft/mobilizon/-/commit/6858bcbbda6d8527bd15b9138e7bb30c5ead72d7))
* **front:** remove leftover console.logs ([6da0dba](https://framagit.org/framasoft/mobilizon/-/commit/6da0dba0fd6d071ce5978802104538d0c2ef7dae))
* **front:** reset page number to 1 when search criteria changes ([d73bafe](https://framagit.org/framasoft/mobilizon/-/commit/d73bafec97cd7d8eda887d21870427262befab0f)), closes [#1272](https://framagit.org/framasoft/mobilizon/-/issues/1272)
* **front:** various UI improvements for group page ([b097567](https://framagit.org/framasoft/mobilizon/-/commit/b0975672c1c06ace364cf47bfcfa39db9c3b712b))
* **graphql:** fix calling GET_GROUP ([2933ee0](https://framagit.org/framasoft/mobilizon/-/commit/2933ee06791a24dbf8c8b2a2eabc67f71e56f361))
* **group:** rephrase "Public Page" to "Announcements", as all posts are not necessary public ([b0a564f](https://framagit.org/framasoft/mobilizon/-/commit/b0a564f64f72f40b6bb9560f9bc0fbea5d099fd7)), closes [#900](https://framagit.org/framasoft/mobilizon/-/issues/900)
* **i18n:** fix Swedish translations error that prevented Participate button from showing up ([643a5b5](https://framagit.org/framasoft/mobilizon/-/commit/643a5b5921f91fed6a9f674c0ab3a36bf2d05835)), closes [#1281](https://framagit.org/framasoft/mobilizon/-/issues/1281)
* **rich media:** fix error handling when resource preview URL leads to empty parsed data ([850b4e2](https://framagit.org/framasoft/mobilizon/-/commit/850b4e2a735e335c4737caa8b60e190613e778ef)), closes [#1279](https://framagit.org/framasoft/mobilizon/-/issues/1279)
* **sharepostmodal:** only show the share warning message if the post is accessible by link ([8e626dc](https://framagit.org/framasoft/mobilizon/-/commit/8e626dce7807640a89770e50ca2621d34d6a5d97))
* **apps:** fix device flow authorization process ([9a457fb](https://framagit.org/framasoft/mobilizon/-/commit/9a457fb011b77b27dc465f1bc7327a08f554ccfb))
* **apps:** fix typo in redirect_uri parameter ([5664625](https://framagit.org/framasoft/mobilizon/-/commit/5664625c1c57ccba947400475414c1301d4bf955))
* **apps:** show scope from device activation in authorize device view ([c9d2074](https://framagit.org/framasoft/mobilizon/-/commit/c9d20748a4dd3e0687515f4776335d0ec9bdfcdc))
* **front:** fix homepage event and groups cards snapping ([8809db5](https://framagit.org/framasoft/mobilizon/-/commit/8809db582ccf45fcd477f46dcf70e106720626a8))
* **front:** fix selecting addresses in autocomplete ([e0488dd](https://framagit.org/framasoft/mobilizon/-/commit/e0488dd87ffc0184162a2ff67a13717e6263d56d))
* include user role in moderator role ([c4d6019](https://framagit.org/framasoft/mobilizon/-/commit/c4d60194a6900a3f9430355c5fbb346d910e4df6))


## 3.1.0-rc.2  (2023-05-30)

### Bug Fixes

* **apps:** fix device flow authorization process ([9a457fb](https://framagit.org/framasoft/mobilizon/-/commit/9a457fb011b77b27dc465f1bc7327a08f554ccfb))
* **apps:** fix typo in redirect_uri parameter ([5664625](https://framagit.org/framasoft/mobilizon/-/commit/5664625c1c57ccba947400475414c1301d4bf955))
* **apps:** show scope from device activation in authorize device view ([c9d2074](https://framagit.org/framasoft/mobilizon/-/commit/c9d20748a4dd3e0687515f4776335d0ec9bdfcdc))
* **front:** fix homepage event and groups cards snapping ([8809db5](https://framagit.org/framasoft/mobilizon/-/commit/8809db582ccf45fcd477f46dcf70e106720626a8))
* **front:** fix selecting addresses in autocomplete ([e0488dd](https://framagit.org/framasoft/mobilizon/-/commit/e0488dd87ffc0184162a2ff67a13717e6263d56d))


## 3.1.0-rc.1  (2023-05-30)

### Bug Fixes

* **discussionlistitem:** remove unecessary parameter in vue router target ([779812c](https://framagit.org/framasoft/mobilizon/-/commit/779812c746cf722dd86bcc0ad3bc58e558c13223))
* **emails:** make sure group notification emails are only sent once per email ([927e95f](https://framagit.org/framasoft/mobilizon/-/commit/927e95f387653c7d620e9051c30843ba49c2d65c))
* **frontend:** event edition UI improvements ([0e14a36](https://framagit.org/framasoft/mobilizon/-/commit/0e14a36c6d30ebe386b2136d29539f3b3e914efc))
* **frontend:** only show map on event edition when we have an address or we want to put in details ([02867e6](https://framagit.org/framasoft/mobilizon/-/commit/02867e6e1482ac8770f94fd2bd00174bb31fbdc7))
* **front:** fix showing current group avatar & banners ([20b4aaa](https://framagit.org/framasoft/mobilizon/-/commit/20b4aaabc97080e85cb68fd03393379c7ef82d95))
* **front:** fix showing current identity avatar & banners ([d0f4721](https://framagit.org/framasoft/mobilizon/-/commit/d0f4721925d0c50340d6db8a4e9f4d3e4ca01457))
* **front:** improve UI of the glossary page ([d47b69d](https://framagit.org/framasoft/mobilizon/-/commit/d47b69d6caa7c4405ab2e573ba407f9b2450c3bb))
* **front:** increase padding next to arrow down in `<select>` elements ([94f186c](https://framagit.org/framasoft/mobilizon/-/commit/94f186ce5080316cd633e0344651b0050c2f14d4))
* **front:** remove cache-only for ABOUT GraphQL details on homepage ([6858bcb](https://framagit.org/framasoft/mobilizon/-/commit/6858bcbbda6d8527bd15b9138e7bb30c5ead72d7))
* **front:** remove leftover console.logs ([6da0dba](https://framagit.org/framasoft/mobilizon/-/commit/6da0dba0fd6d071ce5978802104538d0c2ef7dae))
* **front:** reset page number to 1 when search criteria changes ([d73bafe](https://framagit.org/framasoft/mobilizon/-/commit/d73bafec97cd7d8eda887d21870427262befab0f)), closes [#1272](https://framagit.org/framasoft/mobilizon/-/issues/1272)
* **front:** various UI improvements for group page ([b097567](https://framagit.org/framasoft/mobilizon/-/commit/b0975672c1c06ace364cf47bfcfa39db9c3b712b))
* **graphql:** fix calling GET_GROUP ([2933ee0](https://framagit.org/framasoft/mobilizon/-/commit/2933ee06791a24dbf8c8b2a2eabc67f71e56f361))
* **group:** rephrase "Public Page" to "Announcements", as all posts are not necessary public ([b0a564f](https://framagit.org/framasoft/mobilizon/-/commit/b0a564f64f72f40b6bb9560f9bc0fbea5d099fd7)), closes [#900](https://framagit.org/framasoft/mobilizon/-/issues/900)
* **i18n:** fix Swedish translations error that prevented Participate button from showing up ([643a5b5](https://framagit.org/framasoft/mobilizon/-/commit/643a5b5921f91fed6a9f674c0ab3a36bf2d05835)), closes [#1281](https://framagit.org/framasoft/mobilizon/-/issues/1281)
* **rich media:** fix error handling when resource preview URL leads to empty parsed data ([850b4e2](https://framagit.org/framasoft/mobilizon/-/commit/850b4e2a735e335c4737caa8b60e190613e778ef)), closes [#1279](https://framagit.org/framasoft/mobilizon/-/issues/1279)
* **sharepostmodal:** only show the share warning message if the post is accessible by link ([8e626dc](https://framagit.org/framasoft/mobilizon/-/commit/8e626dce7807640a89770e50ca2621d34d6a5d97))


### Features

* **front:** improve padding on event tags ([7fa452d](https://framagit.org/framasoft/mobilizon/-/commit/7fa452d9e3f9bb2443e571c9a32eaed51e32480a))
* **front:** make admin profile view linkable directly with parameters ([08ce7e2](https://framagit.org/framasoft/mobilizon/-/commit/08ce7e26b73045279261ab87a14cb4f3dab5df1e))
* **front:** make profile members link to profile on group admin view and the reverse ([96129d2](https://framagit.org/framasoft/mobilizon/-/commit/96129d2339133027220d3b5fcb1c52f84bcc5cbb))
* **front:** make profiles and group admin views default to local ([3e0324d](https://framagit.org/framasoft/mobilizon/-/commit/3e0324d36ec5a8aa388e6b5d598a6f9a0c596797))
* **front:** redirect user to homepage on disconnect when currently on private page ([d5a6df9](https://framagit.org/framasoft/mobilizon/-/commit/d5a6df9940fb458c5dbaee149015c02ebc370c6b)), closes [#1278](https://framagit.org/framasoft/mobilizon/-/issues/1278)
* **front:** show skeleton content on event view until the event is loaded ([dc3b93f](https://framagit.org/framasoft/mobilizon/-/commit/dc3b93ffb5a4b072aec792533fd6e4b58ed7a893))
* **i18n:** activate croatian language ([94182ae](https://framagit.org/framasoft/mobilizon/-/commit/94182aed2d8a22d00534f6376dfda2658bc8ba7e))
* **i18n:** activate japanese language ([6bd8034](https://framagit.org/framasoft/mobilizon/-/commit/6bd8034fe816a432c3547de6d1ad8a18e73dc314)), closes [#1293](https://framagit.org/framasoft/mobilizon/-/issues/1293)
* **post:** show post visibily in PostListItem component ([ec7ca4d](https://framagit.org/framasoft/mobilizon/-/commit/ec7ca4ddf18a38cf6f51d38b540eecc9858f3c98))


## 3.1.0-beta.2  (2023-05-23)

### Bug Fixes

* include user role in moderator role ([c4d6019](https://framagit.org/framasoft/mobilizon/-/commit/c4d60194a6900a3f9430355c5fbb346d910e4df6))


## 3.1.0-beta.1  (2023-05-17)

### Features

* **API:** Allow to create apps, with permissions and both Authorization Code Flow and Device Flow
* **addresses:** Allow to enter manual addresses ([85d643d](https://framagit.org/framasoft/mobilizon/-/commit/85d643d0ecd5e7504f32953b9ed1509697b915e2))
* **docker:** Specify the folder where tzdata downloads data so that it can be used in a volume ([4bb0625](https://framagit.org/framasoft/mobilizon/-/commit/4bb062528f12be530a3754ca23c1bc6dbc862e5a)), closes [#1280](https://framagit.org/framasoft/mobilizon/-/issues/1280)
* **spam:** Introduce checking new accounts, events & comments for spam with the help of Akismet ([317a343](https://framagit.org/framasoft/mobilizon/-/commit/317a3434b221a1a91b66d8443984269404863a8e))
* **rate-limiting:** Introduce rate-limiting on some endpoints ([c07ba3a5](https://framagit.org/framasoft/mobilizon/-/commit/c07ba3a5d19c419ef8aaf3ea9ca6e7f48e4f4487))

### Bug Fixes

* **global-search:** Add option values in debug log before calling global search service ([8141bb0](https://framagit.org/framasoft/mobilizon/-/commit/8141bb0acbc4eb02a917c5bc18712d0d954c4ee5))
* **apps:** Fix cleaning application data background job ([aa20f69](https://framagit.org/framasoft/mobilizon/-/commit/aa20f6991127ddee546fc0b867298c1342dbcb4d))
* **apps:** Show message when the user doesn't have approved apps yet ([e0ee9c1](https://framagit.org/framasoft/mobilizon/-/commit/e0ee9c143b0335753db5dfae19e324781d55bd4e))
* **auth:** Handle logging-in with disabled auth provider ([a22a5e3](https://framagit.org/framasoft/mobilizon/-/commit/a22a5e3cb924869e32cb9ed71dab3e03d91c018f))
* **backend:** Fix Mobilizon.Events.list_participations_for_user_query/1 ([bcf6fd8](https://framagit.org/framasoft/mobilizon/-/commit/bcf6fd893c762c12b63d7e02da43cd5c05db509b))
* **backend:** Handle CLDR data having no standard property for a language ([dbe2da7](https://framagit.org/framasoft/mobilizon/-/commit/dbe2da79c3aa1543b87dce61b5fd90195fb53afe))
* **backend:** Ignore group mentions for now ([b5f106b](https://framagit.org/framasoft/mobilizon/-/commit/b5f106b0a81fefba3203f8ec5855e834a2078222))
* **back:** Improve error message when requesting reset passwords and new instructions ([1c1d0d4](https://framagit.org/framasoft/mobilizon/-/commit/1c1d0d47d70cf19abe5be42e7ec3a73656a8172b))
* **back:** Replace NaiveDateTime uses with DateTime for consistency ([8ea00e7](https://framagit.org/framasoft/mobilizon/-/commit/8ea00e7c1827ce3056ae51968a62fb3dc03ac6eb))
* **back:** Various small fixes in backend ([2a57340](https://framagit.org/framasoft/mobilizon/-/commit/2a57340a82e414e69924ad89e8db9fc326742cc7))
* bind pagination current prop ([4bcf572](https://framagit.org/framasoft/mobilizon/-/commit/4bcf572c54d904587d0409e2eb68b4ca6cf48fec))
* **federation:** Account suspension should use actor in question as author and not relay actor ([79b48da](https://framagit.org/framasoft/mobilizon/-/commit/79b48da22209a8b2f1b234b8b8e121543a39b22b))
* **feeds:** Only provide future events in ICS/Atom feeds ([f3a4431](https://framagit.org/framasoft/mobilizon/-/commit/f3a443138a0e1e6cf34fc593f5c174d56c21e904)), closes [#1246](https://framagit.org/framasoft/mobilizon/-/issues/1246)
* Fix type of variable in navbar ([50ab531](https://framagit.org/framasoft/mobilizon/-/commit/50ab531156214f883cb03f785ccf65e3f19ef50e))
* **follow-instances:** Show correct error message when trying to follow already following actor ([d969c66](https://framagit.org/framasoft/mobilizon/-/commit/d969c6648f15e1ed280169a4c55d612bb002f03f))
* **front:** Fix about sections titles ([487f406](https://framagit.org/framasoft/mobilizon/-/commit/487f4069b14fde6304c9a42cec5b1c1af79814c5))
* **front:** Fix autocomplete attribute in o-inputitems after Oruga new version BC ([d2ba732](https://framagit.org/framasoft/mobilizon/-/commit/d2ba732b8b51986b739f6fbe3d74fa68e4b74ba0))
* **front:** Fix behaviour when deleting an event from event list ([cfd10ea](https://framagit.org/framasoft/mobilizon/-/commit/cfd10ea96078f03ad3b4f5682e37078ffae16ee4))
* **front:** Fix event list month order ([63c9ed6](https://framagit.org/framasoft/mobilizon/-/commit/63c9ed62de94d6d150798c949bad3d8a2dd4db23)), closes [#1244](https://framagit.org/framasoft/mobilizon/-/issues/1244)
* **front:** Fix instances list pagination ([8543204](https://framagit.org/framasoft/mobilizon/-/commit/8543204bd95de886d8d35bd491f23ecbc0a6ef8d)), closes [#1277](https://framagit.org/framasoft/mobilizon/-/issues/1277)
* **front:** Fix pagination display on dark mode ([4375438](https://framagit.org/framasoft/mobilizon/-/commit/4375438dc9fd2f1c5c9d7ed6670dde04f2da520f))
* **front:** Fix style of My Events participations ([35b07dc](https://framagit.org/framasoft/mobilizon/-/commit/35b07dceaa41c74c28ea49655b755e341f56df32))
* **front:** Focus report comment input in report modal ([2c28312](https://framagit.org/framasoft/mobilizon/-/commit/2c28312fc957901b86c2f3d1db8fc3376f505d37)), closes [#1236](https://framagit.org/framasoft/mobilizon/-/issues/1236)
* **front:** Handle "Failed to fetch dynamically imported module" errors by refreshing the page ([3d21a06](https://framagit.org/framasoft/mobilizon/-/commit/3d21a067897e4aa24f6404686ca6896044584796))
* **front:** Improve Delete account modal UI ([c420bbc](https://framagit.org/framasoft/mobilizon/-/commit/c420bbccc9bd1c348e41904e826dc49c71d7eeb4))
* **front:** Improve resend inscription instructions view and show error when appropriate ([5563052](https://framagit.org/framasoft/mobilizon/-/commit/55630527957d4f6a2e1e6845e64a92bc4794efc8))
* **front:** No cache-only for config ([8dcb76c](https://framagit.org/framasoft/mobilizon/-/commit/8dcb76c30d4fa835837fd3b3833f83682fbae615))
* **front:** Small UI fixes on identity pickers ([6faafd6](https://framagit.org/framasoft/mobilizon/-/commit/6faafd639303e4b57ed81db2ffb5db4ad598b904))
* **i18n:** Update translations ([3b7dbcd](https://framagit.org/framasoft/mobilizon/-/commit/3b7dbcd71f0d19d5e723a03c56ca0b1abbd16f5d))
* **map:** Fix style of the map marker ([c7b90cd](https://framagit.org/framasoft/mobilizon/-/commit/c7b90cd60a14abea7aebab7e1d87f37a44371f7c))
* **map:** Only show map details when needed ([23b5e59](https://framagit.org/framasoft/mobilizon/-/commit/23b5e5930cb9bdb57b1d7fa3ec899d7e4d3571be))
* **map:** Only show marker if we have it's position ([f0cc5ff](https://framagit.org/framasoft/mobilizon/-/commit/f0cc5ffb8feb2f4d70416792a8ab2f4f44bfba85))
* **password-reset:** Lower time before being available to reset password or resend instructions ([73eb460](https://framagit.org/framasoft/mobilizon/-/commit/73eb4603b185c341b63481ed934f66e19aa0784f))
* **search:** Fix event search order ([a4e7ee3](https://framagit.org/framasoft/mobilizon/-/commit/a4e7ee37bedc63b2193a401c801b3b1298f566d2))
* **typespec:** Fix missing return type in typespec ([2043c98](https://framagit.org/framasoft/mobilizon/-/commit/2043c98717e8621b3953d347be0b4a35f494af98))
* Change the way preferredUsername is synced ([a73e5a08](https://framagit.org/framasoft/mobilizon/-/commit/a73e5a085ef48a88dbb8f9c407df0430ca89fe1f))
* datetimepicker: change colors for day & time selectors on dark mode ([b18e8fd3](https://framagit.org/framasoft/mobilizon/-/commit/b18e8fd37c76190ca7f6db82e408cdb005d1810a))
* Save IP and login date from directly registered accounts ([1db5c4ae](https://framagit.org/framasoft/mobilizon/-/commit/1db5c4ae2d49d5adbda2c0825ee0320322b525d6))
* Make sure every cache is properly cleared when managing an event ([f531c39b](https://framagit.org/framasoft/mobilizon/-/commit/f531c39b7e8829a5e3ff68f624b04e12266f2148))
* Add page title for Categories view ([0775814e](https://framagit.org/framasoft/mobilizon/-/commit/0775814e19e6f6ddde564f7a29ae80fab2175d3f))
* Fix notifications settings not working ([31fd99bd](https://framagit.org/framasoft/mobilizon/-/commit/31fd99bd3760872e452351b33765d25b2b9720f2))


## 3.0.3 - 2022-12-22

### Fixed

- Add missing OpenSSL 1.1 in Docker image

## 3.0.2 - 2022-12-22

### Fixed

- Fix unfollowing group
- Limit the size of the IP(v6) field in the user admin view
- Fix terms and privacy view
- Use the correct value of current locale
- Fix editing group events as a group moderator
- Consider timezone for start time also when end date is hidden
- Fix loading group members in organizer picker
- Fix changing email & password
- Add missing icon
- Fix instances filter
- Fix logging from 3rd-party auth provider

## 3.0.1 - 2022-11-22

### Fixed

- Compatibility with Python 3.11 for exports that reply on Python code.
- Formatting of fallback locales
- Allow to specify database port for Docker configuration
- Assets in production environment
- Changing event uuid didn't change event data
- Make sure maximumAttendeeCapacity is a number, not a string
- Prevent AP collection page number being < 1
- Fix approving/rejecting group members and followers
- Fix 3rd-party auth links
- Test Intl.ListFormat availability and add fallback
- Set correct Content-Type on all AP endpoints
- Don't notify group members & followers from new draft event
- Register missing ExitToApp icon
- Fix comment display

## 3.0.0 - 2022-11-08

### Added

- Add global search support, allowing to use https://search.joinmobilizon.org as a centralized event and group database
- Add ability to filter search by categories and language
- Add ability to explore search results on a map view
- Add dark theme support and setting to toggle light/dark mode
- Add categories view
- Allow to disable non-SSO login
- Support CSP report_uri, report_to and the Report-To and Reporting-Endpoints headers
- Support for Elixir 1.14 and Erlang OTP 25.

### Changed

- Homepage has been redesigned
- Search view has been redesigned
- Internal illustration pictures are now only served using WebP.
- Improved the pertinence of related events
- Light front-end performance improvements
- Various UI and A11Y fixes on the event page
- Handle categories page being empty
- UI improvements of comments
- UI improvements of reports
- Various UI improvement in event and group view
- Add breadcrumb trail on Post view
- Always lowercase the emails before trying to reset password
- Make text editor heading level start at h3, h4, h5
- Remove obscure reference to Douglas Adams
- Don't inline phoenix manifest
- Show a proper error message when failure to register to an event
- Order categories by translated label
- Show registration button also if registration allow list is used
- Add logging for when cached iCalendar feed data can't be found
- Add an error log when we try to update the relay actor
- Lower loglevel of error when creating a new person
- Add unique constraint on event URL
- Allow to view more than 10 drafts events on my events view
- Add CSP Policy for pictures
- Don't treat notification for a deleted event as an error
- Truncate resource description preview after 350 characters
- Lower loglevel of resource insertion error
- Resources and discussions views improvements
- Add context to error when removing an upload file following actor suspension
- Allow for resource providers to register a csp policy
- Add loading="lazy" to some images, except categories in viewport
- Add GraphQL operation name, user ID and actor name in logs
- Add empty alt attribute to uploaded pictures (for now)
- Allow release build failures in CI for all non-amd64 architectures
- Increase timeout needed to build page
- Handle nothing found by unsplash for location

### Fixed

- Fixed deleting actor when participations association is not preloaded
- Fixed rendering JSON-LD for an event with a single address (no online location)
- Address selector
- Group location edition
- Reconfigure plug at runtime with env
- Fix global search term
- Fix custom icons in metadata list
- Handle unknown icon
- Only preload svg pictures on homepage
- Don't add empty search parameters to global search engine
- Fix getting categories from global search engine
- Remove unused deps
- Only show one pagination bar when searching in both events & groups
- Run build multiarch release on tags too
- Don't start mobilizon server when running migrations
- Run phx.digest before mix release
- Fix event card background color behind picture
- Fix position of the « no events found » message
- Add distinct clause to search events
- Fix showing past events on group page
- Fix display of group invitations
- Fix leaving a group
- Fix group events order
- Prevent loading group membership status before we get person information
- Prefix setInterval with window
- Fix fetching events with addresses that's not objects
- Fix dashboard view
- Fix anonymous & remote participation pages
- Fix anonymous/remote participation button
- Do not list drafts in upcoming / old events event if instance moderator
- Make sure group is refreshed after action
- Fix deleting person detached from user
- Fix pagination number text color in dark theme
- Fix post sharing URL
- Fix current format status of text not displayed in text editor
- Fix moving resources
- Fix multiselect of resources
- Properly handle un-needed background jobs
- Properly handle replying to an event that has been deleted
- Propertly handle other errors when receiving a comment
- Fix event integrations
- Prevent loading authorized groups when current actor isn't loading in OrganizerPickerWrapper
- Fix building CSP policy
- Fix event map view
- Various front-end fixes
- Handle error when fetching object from tombstone
- Fixed upcoming event groups display on homepage view
- Fixed Ecto Dev warning on compilation
- Adapt white parts in Mobilizon logo to current color
- Register missing BellOutline and BellOffOutline icons
- Don't load group status when unlogged
- Fix order of useHead registration on JoinGroupWithAccount view
- Fix profile@instance translation
- Handle :http_not_found as an error when deleting an object
- Handle suspending actors with special type
- Add fallback handler for can_send_activity?
- Properly log if we can't notify group follower

### Security

- Correctly escape user-defined names in emails

### Internal
- Build on Elixir 1.14.1 and Erlang OTP 25.
- Migrate from Vue 2 and Vue Class Component to Vue 3 and the Composition API
- Migrate from Bulma and Buefy to TailwindCSS and Oruga

### Tests

#### Unit Tests
- Rewrote tests using Vitest

#### E2E Tests
- Renabled E2E tests
- Rewrote tests from Cypress to Playwright

## 3.0.0-rc.6 - 2022-11-07

### Fixed

- Fixed upcoming event groups display on homepage view
- Fixed Ecto Dev warning on compilation

## 3.0.0-rc.5 - 2022-11-06

### Changed

- Allow release build failures in CI for all non-amd64 architectures

## 3.0.0-rc.4 - 2022-11-06

### Changed

- Add loading="lazy" to some images, except categories in viewport
- Add GraphQL operation name, user ID and actor name in logs
- Add empty alt attribute to uploaded pictures (for now)

### Fixed

- Fix building CSP policy
- Fix event map view
- Various front-end fixes
- Handle error when fetching object from tombstone

## 3.0.0-rc.3 - 2022-11-04

### Added

- Support CSP report_uri, report_to and the Report-To and Reporting-Endpoints headers

### Changed

- Add CSP Policy for pictures
- Don't treat notification for a deleted event as an error
- Truncate resource description preview after 350 characters
- Lower loglevel of resource insertion error
- Resources and discussions views improvements
- Add context to error when removing an upload file following actor suspension
- Allow for resource providers to register a csp policy

### Fixed
- Fix moving resources
- Fix multiselect of resources
- Properly handle un-needed background jobs
- Properly handle replying to an event that has been deleted
- Propertly handle other errors when receiving a comment
- Fix event integrations
- Prevent loading authorized groups when current actor isn't loading in OrganizerPickerWrapper

## 3.0.0-rc.2 - 2022-11-02

### Added

- Add setting to toggle light/dark mode
- Allow to disable non-SSO login

### Changed

- UI improvements of comments
- UI improvements of reports
- Various UI improvement in event and group view
- Add breadcrumb trail on Post view
- Always lowercase the emails before trying to reset password
- Make text editor heading level start at h3, h4, h5
- Remove obscure reference to Douglas Adams
- Don't inline phoenix manifest
- Show a proper error message when failure to register to an event
- Order categories by translated label
- Show registration button also if registration allow list is used
- Add logging for when cached iCalendar feed data can't be found
- Add an error log when we try to update the relay actor
- Lower loglevel of error when creating a new person
- Add unique constraint on event URL
- Allow to view more than 10 drafts events on my events view

### Fixed

- Fix event card background color behind picture
- Fix position of the « no events found » message
- Add distinct clause to search events
- Fix showing past events on group page
- Fix display of group invitations
- Fix leaving a group
- Fix group events order
- Prevent loading group membership status before we get person information
- Prefix setInterval with window
- Fix fetching events with addresses that's not objects
- Fix dashboard view
- Fix anonymous & remote participation pages
- Fix anonymous/remote participation button
- Do not list drafts in upcoming / old events event if instance moderator
- Make sure group is refreshed after action
- Fix deleting person detached from user
- Fix pagination number text color in dark theme
- Fix post sharing URL
- Fix current format status of text not displayed in text editor

### Security

- Correctly escape user-defined names in emails

## 3.0.0-rc.1 - 2022-10-18

No changes since beta.3

## 3.0.0-beta.3 - 2022-10-17

### Fixed
- Don't add empty search parameters to global search engine
- Fix getting categories from global search engine
- Remove unused deps
- Only show one pagination bar when searching in both events & groups
- Run build multiarch release on tags too
- Don't start mobilizon server when running migrations
- Run phx.digest before mix release


## 3.0.0-beta.2 - 2022-10-11

### Changed

- Improved the pertinence of related events
- Light front-end performance improvements
- Various UI and A11Y fixes on the event page
- Handle categories page being empty

### Fixed

- Address selector
- Group location edition
- Reconfigure plug at runtime with env
- Fix global search term
- Fix custom icons in metadata list
- Handle unknown icon
- Only preload svg pictures on homepage

## 3.0.0-beta.1 - 2022-09-27

### Added

- Add global search support, allowing to use https://search.joinmobilizon.org as a centralized event and group database
- Add ability to filter search by categories and language
- Add ability to explore search results on a map view
- Add dark theme support
- Add categories view
- Support for Elixir 1.14 and Erlang OTP 25.

### Changed

- Homepage has been redesigned
- Search view has been redesigned
- Internal illustration pictures are now only served using WebP.

### Fixed

- Fixed deleting actor when participations association is not preloaded
- Fixed rendering JSON-LD for an event with a single address (no online location)

### Internal
- Build on Elixir 1.14 and Erlang OTP 25.
- Migrate from Vue 2 and Vue Class Component to Vue 3 and the Composition API
- Migrate from Bulma and Buefy to TailwindCSS and Oruga

### Tests

#### Unit Tests
- Rewrote tests using Vitest

#### E2E Tests
- Renabled E2E tests
- Rewrote tests from Cypress to Playwright

## 2.1.0 - 2022-05-16

### Added

- Added an event category field. Administrators can extend the pre-configured list of categories through configuration.
- Added possibility for administrators to have analytics (Matomo, Plausible supported) and error handling (Sentry supported) on front-end.
- Redesigned federation admin section with dedicated instance pages
- Allow to filter moderation reports by domain
- Added a button to go to past events of a group if it has no upcoming events
- Add Überauth CAS Strategy
- Add a CLI command to delete actors

### Changed

- Changed mailer library from Bamboo to Swoosh, should fix emails being considered spam. **Some configuration changes are required, see [UPGRADE.md](https://framagit.org/framasoft/mobilizon/-/blob/main/UPGRADE.md).**
- Expose some fields to ActivityStreams event representation: `isOnline`, `remainingAttendeeCapacity` and `participantCount`
- Expose a new field to ActivityStreams group representation: `memberCount`
- Improve group creation errors feedback
- Only display locality in event card
- Stale groups are now excluded from group search
- Event default visibility is now set according to group privacy setting
- Remove Koena Connect button
- Hide the whole metadata block if group has no description
- Increase task timeout in Refresher to 60 seconds
- Allow webfinger to be fetched over http (not https) in dev mode
- Improve reactions when approving/rejecting an instance follow
- Improve instance admin view for mobile
- Allow to reject instance following
- Allow instance to have non-standard ports
- Add pagination to the instances list
- Eventually fetch actors in mentions
- Improve IdentityPicker, JoinGroupWithAccount and ActorInline components
- Various group and posts improvements
- Update schema.graphql file
- Add "Accept-Language" header to sentry request metadata
- Hide address blocks when address has no real data
- Remove obsolete attribute `type="text/css"` from `<style>` tags
- Improve actor cards integration
- Use upstream dependencies for Ueberauth providers
- Include ongoing events in search
- Send push notification into own task
- Add appropriate timeouts for Repo.transactions
- Add a proper error message when adding an instance follow that doesn't respond
- Allow the instance to be followed from Mastodon (through relays)
- Remove unused fragment from FETCH_PERSON GraphQL query

### Fixed

- Fixed actor refreshment being impossible
- Fixed ical export for undefined datetimes
- Fixed parsing links with hashtag characters
- Fixed fetching link details from Twitter
- Fixed Thunderbird accessing ICS feed endpoint with special `Accept` HTTP header
- Make sure every ICS/Feed caches are emptied when modifying entities
- Fixed time issues with DST changes
- Fixed group preview card not truncating description
- Fixed redirection after login
- Fixed user admin section showing button to confirm user when the user is already confirmed
- Fixed creating event from group view not always setting the group as organizer
- Fixed invalid addresses blocking event metadata preview rendering
- Fixed group deletion with comments that caused foreign key issues
- Fixed incoming Accept activities from participations we don't already have
- Fixed resources that didn't have metadata size limits
- Properly fallback to UTC when sending notifications and the user doesn't have a timezone setting set
- Fix posts creation
- Fix rejecting instance follow
- Fix pagination of group events
- Add proper fallback for when a TZ isn't registered
- Hide side of report modal on low width screens
- Fix Telegram Logo being replaced with Mastodon logo in ShareGroupModal
- Change URL for Mastodon Share Manager
- Fix receiving Flag activities on federated events
- Fix activity notifications by preloading user.activity_settings
- Fix text overflow on group card description
- Exclude tags with more than 40 characters from being extracted
- Avoid duplicate tags with different casing
- Fix invalid HTML (`<div>` inside `<label>`)
- Fix latest group not refreshing in admin section
- Add missing "relay@" part of federated address to follow
- Fix Ueberauth use of CSRF with session
- Fix being an administrator when using 3rd-party auth provider
- Make sure activity recipient can't be nil
- Make sure users can't create profiles or groups with non-valid patterns
- Add description field to address representation
- Make sure prompt show the correct message and not just "Continue?" in mix mode
- Make sure activity notification recaps can't be sent multiple times
- Fix group notification of new event being sent multiple times
- Fix links to group page in group membership emails and participation
- Fix clicking on map crashing the app

### Translations

- Arabic
- Basque
- Belarusian
- Bengali
- Catalan
- Chinese (Traditional)
- Croatian
- Czech
- Danish
- Dutch
- Esperanto
- Finnish
- French
- Gaelic
- Galician
- German
- Hebrew
- Hungarian
- Indonesian
- Italian
- Japanese
- Kabyle
- Kannada
- Norwegian Nynorsk
- Occitan
- Persian
- Polish
- Portuguese
- Portuguese (Brazil)
- Russian
- Slovenian
- Spanish
- Swedish
- Welsh

## 2.1.0-rc.6 - 2022-05-11

Changes since rc.5:

- Allow the instance to be followed from Mastodon (through relays)
- Make sure activity recipient can't be nil
- Make sure users can't create profiles or groups with non-valid patterns
- Add description field to address representation
- Make sure prompt show the correct message and not just "Continue?" in mix mode
- Add a CLI command to delete actors
- Make sure activity notification recaps can't be sent multiple times
- Fix group notification of new event being sent multiple times
- Fix links to group page in group membership emails and participation
- Fix clicking on map crashing the app
- Remove unused fragment from FETCH_PERSON GraphQL query

## 2.1.0-rc.5 - 2022-05-06

Changes since rc.4:

- Add appropriate timeouts for Repo.transactions
- Remove OS-specific packages
- Remove refresh instance triggers
- Add a proper error message when adding an instance follow that doesn't respond

## 2.1.0-rc.4 - 2022-05-03

Changes since rc.3:

- Use upstream dependencies for Ueberauth providers
- Fix Ueberauth use of CSRF with session
- Fix being an administrator when using 3rd-party auth provider
- Include ongoing events in search
- Send push notification into own task
- Add Überauth CAS Strategy

## 2.1.0-rc.3 - 2022-04-24

Changes since rc.2:

- Fix activity notifications by preloading user.activity_settings
- Add "Accept-Language" header to sentry request metadata
- Hide address blocks when address has no real data
- Fix text overflow on group card description
- Exclude tags with more than 40 characters from being extracted
- Avoid duplicate tags with different casing
- Fix invalid HTML (<div> inside <label>)
- Remove attribute type="text/css" from <style> tags
- Improve actor cards integration
- Fix latest group not refreshing in admin section
- Add missing "relay@" part of federated address to follow

## 2.1.0-rc.2 - 2022-04-20

Changes since rc.1:

- Hide the whole metadata block if group has no description
- Increase task timeout in Refresher to 60 seconds
- Allow webfinger to be fetched over http (not https) in dev mode
- Fix rejecting instance follow
- Allow instance to have non-standard ports
- Improve reactions when approving/rejecting an instance follow
- Improve instance admin view for mobile
- Allow to reject instance following
- Fix pagination of group events
- Add pagination to the instances list
- Upgrade deps
- Eventually fetch actors in mentions
- Add proper fallback for when a TZ isn't registered
- Improve IdentityPicker
- Hide side of report modal on low width screens
- Improve JoinGroupWithAccount component
- Various group and posts improvements
- Fix Telegram Logo being replaced with Mastodon logo in ShareGroupModal
- Change URL to Mastodon Share Manager
- Improve ActorInline component
- Avoid assuming we're on Debian-based in release build
- Fix receiving Flag activities on federated events
- Update schema.graphql file

## 2.1.0-rc.1 - 2022-04-18

Changes since beta.3:

- Fix posts creation
- Fix some typespecs
- Remove Koena Connect button
- Update dependencies

## 2.1.0-beta.3 - 2022-04-09

Changes since beta.2:

- Add Fedora and Alpine builds

## 2.1.0-beta.2 - 2022-04-08

Changes since beta.1 :

- Build release packages for several distributions (Debian Bullseye, Debian Buster, Ubuntu Focal, Ubuntu Bionic) because of libc version changes

## 2.1.0-beta.1 - 2022-04-07

### Added

- Added an event category field. Administrators can extend the pre-configured list of categories through configuration.
- Added possibility for administrators to have analytics (Matomo, Plausible supported) and error handling (Sentry supported) on front-end.
- Redesigned federation admin section with dedicated instance pages
- Allow to filter moderation reports by domain
- Added a button to go to past events of a group if it has no upcoming events

### Changed

- Changed mailer library from Bamboo to Swoosh, should fix emails being considered spam. **Some configuration changes are required, see below.**
- Expose some fields to ActivityStreams event representation: `isOnline`, `remainingAttendeeCapacity` and `participantCount`
- Expose a new field to ActivityStreams group representation: `memberCount`
- Improve group creation errors feedback
- Only display locality in event card
- Stale groups are now excluded from group search
- Event default visibility is now set according to group privacy setting

### Fixed

- Fixed actor refreshment being impossible
- Fixed ical export for undefined datetimes
- Fixed parsing links with hashtag characters
- Fixed fetching link details from Twitter
- Fixed Thunderbird accessing ICS feed endpoint with special `Accept` HTTP header
- Make sure every ICS/Feed caches are emptied when modifying entities
- Fixed time issues with DST changes
- Fixed group preview card not truncating description
- Fixed redirection after login
- Fixed user admin section showing button to confirm user when the user is already confirmed
- Fixed creating event from group view not always setting the group as organizer
- Fixed invalid addresses blocking event metadata preview rendering
- Fixed group deletion with comments that caused foreign key issues
- Fixed incoming Accept activities from participations we don't already have
- Fixed resources that didn't have metadata size limits
- Properly fallback to UTC when sending notifications and the user doesn't have a timezone setting set

### Translations

- Arabic
- Basque
- Belarusian
- Bengali
- Catalan
- Chinese (Traditional)
- Croatian
- Czech
- Danish
- Dutch
- Esperanto
- Finnish
- French
- Gaelic
- Galician
- German
- Hebrew
- Hungarian
- Indonesian
- Italian
- Japanese
- Kabyle
- Kannada
- Norwegian Nynorsk
- Occitan
- Persian
- Polish
- Portuguese
- Portuguese (Brazil)
- Russian
- Slovenian
- Spanish
- Swedish
- Welsh

## 2.0.2 - 2021-12-22

### Changed

- Improved handling of media file deletion
- Releases and Docker image are now using Elixir 1.13

### Fixed

- Fixed position of tentative tag on event cards
- Fixed text overflow when a link is too long in event mobile view
- Fixed filtering user own memberships and group members in event organizer & contacts picker
- Fixed first day of week not depending on locale in the datetime picker
- Fixed the admin page when a group/profile/user was not found
- Fixed group members pagination on admin group profile view
- Fixed admin edition of the instance's language

### Translations

- Croatian
- Czech
- Esperanto
- German
- Hebrew
- Occitan
- Persian
- Russian
- Spanish

## 2.0.1 - 2021-11-26

### Changed

- Remove litepub context

### Fixed

- Make sure my group upcoming events are ordered by their start date
- Fix event participants pagination
- Always focus the search field after results have been fetched
- Don't sign fetches to instance actor when refreshing their keys
- Fix reject of already following instances
- Added missing timezone data to the Docker image
- Replace @tiptap/starter-kit with indidual extensions, removing unneeded extensions that caused issues on old Firefox versions
- Better handling of Friendica Update activities without actor information
- Always show pending/cancelled status on event cards
- Fixed nightly docker build
- Refresh loggeduser information before the final step of onboarding, avoiding loop when finishing onboarding
- Handle tz_world data being absent

### Translations

- Croatian (New !)
- Czech
- Gaelic
- Hungarian
- Indonesian
- Welsh (New !)

## 2.0.0 - 2021-11-23

Please read the [UPGRADE.md](https://framagit.org/framasoft/mobilizon/-/blob/main/UPGRADE.md#upgrading-from-13-to-20) file as well.

### Added

- Added possibility to follow groups and be notified from new upcoming events
- Export list of participants to CSV, `PDF` and `ODS`
- Allow to set timezone for an event. The timezone is automatically defined from the address if one is defined. If the event timezone is different than the user's current one, a toggle is shown to switch between the two.
- Added initial support for Right To Left languages (such as arabic) and [BiDi](https://en.wikipedia.org/wiki/Bidirectional_text)
- Group followers and members get an notification email by default when a group publishes a new event (subject to activity notification settings)
- Group admins can now approve or deny new memberships
- Build releases in `arm` and `arm64` format in addition to `amd64`
- Build Docker images in `arm` and `arm64` format in addition to `amd64`
- Added possibility to indicate the event is fully online
- Added possibility to search only for online events
- Added possibility to search only in past events
- Detect event, comments and posts languages automatically. Allows setting language
- Allow to change an user's password through the users.modify mix task
- Add instance setting so that only the admin can create groups
- Add instance setting so that only groups can create events
- Added JSON-LD metadata about the event in emails
- Added a quick link to email notification settings at the bottom of emails
- Allow to access Mobilizon with a specific language directly by using `https://instance.tld/lang` where `lang` is a language supported by Mobilizon
- Added organizer actor name (profile or group) in the icalendar export
- Add initial support for federation with Gancio

### Changed

- Multiple UI improvements, including post, event and participation cards, discussions and emails. The « My Events » page was also redesigned to allow showing events from your groups.
- Various accessibility improvements
- Event update notification is send to participants ~30 minutes after the event update, so that successive edits are throttled.
- Event, post and comments titles and content now have expose their detected language in HTML, for improved screen reader experience
- Delete current actor ID as well from local storage when unlogging
- Show a default text for instance contact in default terms text when no instance contact is set
- Only show locatecontrol button in leaflet map when we can do geolocation
- Disable push column in notification settings when push is not available
- Show actual language instead of language code in Users admin view
- Empty old & new passwords fields when successful password change
- Don't link to the group page from admin when actor is suspended
- Warn participants when the event organizer is suspended (and therefore the event cancelled)
- Improve metadata on public page
- Make sure some event action pages (participate remotely or without an account) don't get indexed by search engines
- Only send `Tombstone` element in `Delete` activities, not the whole previous deleted element.
- Make sure `Delete` activity are send correctly to everyone
- Only add address and tags to event icalendar export if they exist
- `master` branch has been renamed to `main`
- Mention following groups on the registration page
- Add missing group name to activity notifications
- Warn while registering and logging when the email contains uppercase characters
- Improve json-ld metadata on event live streams
- Add "eventAttendanceMode" to JSON-ld schema.org event representation
- Improve sending pending participation notifications
- Add "formerType" and "delete" attributes on Tombstones ActivityPub objects representation
- Improve MyEvents page description text

### Removed

- Support for Elixir < 1.12 and OTP < 22

### Fixed

- Fix tags autocomplete
- Fix config onboarding after LDAP initial connexion
- Fix events pagination on tags page
- Fixed deduplicated files from orphan media being deleted as well
- Fix deleting own account
- Fix search returning user profiles instead of only groups
- Fix federating geo coordinates
- Fix an issue with group activity items when moving resources
- Fix an issue with Identity Picker
- Fix an issue with TagInput
- Fix an issue when leaving a group
- Fix admin settings edition
- Fix an issue when showing public page of suspended group
- Removed non existing page (`/about/mobilizon`) from sitemap
- Fix action logs containing group suspension events
- Fixed group physical address not exposed to ActivityPub
- Release front-end files are no longer in duplicate
- Only show datetime timezone toggle on event if the timezone offset is different from our own
- Fix error when determining audience for Discussion when deleting a comment
- Fix a couple of accessibility issues
- Limit to acceptable tags when pasting raw HTML into comment fields on front-end
- Fixed group map display
- Fixed updating group physical address
- Allow group members to access group drafts
- Improve group refreshment workflow
- Fixed date signature generation for federation
- Fixed an issue when duplicating a group event from another profile
- Fixed event metadata not saved on eventcreation
- Use a different pagination parameter for searched events and featured events on search page
- Fixed creating group activities when creating events with some fields
- Move release package at correct path for CI upload
- Fixed event contacts that were not exposed and fetched over federation
- Don't sign fetch when fetching actor for a given signature
- Some various HTTP signatures issues
- Fixed actor AP representation of avatar
- Handle errors when fetching actor pictures
- Fixed sending group events to followers on Mastodon
- Fixed actors avatars and banners being deleted if the same file was also an orphan media
- Fix spacing in organizer picker
- Increase number of close events and follow group events
- Fix accessing user profile in admin section
- Set initial values for some EventMetadata elements, fixing submitting them right away with no value
- Avoid giving an error page if the apollo futureParticipations query is undefined
- Fixed path to exports in production
- Fixed padding below truncated title of event cards
- Fixed exports that weren't enabled in Docker
- Fixed error page when event end date is null
- Fixed event language not being allowed to be null

### Security

- Fixed private messages sent as event replies from Mastodon that were shown publically as public comments. They are now discarded.

### Translations

- Czech
- Gaelic
- German
- Hungarian
- Indonesian
- Norwegian Nynorsk
- Occitan
- Persian
- Portuguese (Brazil)
- Russian
- Slovenian
- Spanish

## 2.0.0-rc.3 - 2021-11-22

This lists changes since 2.0.0-rc.3. Please read the [UPGRADE.md](https://framagit.org/framasoft/mobilizon/-/blob/main/UPGRADE.md#upgrading-from-13-to-20) file as well.

### Fixed

- Fixed path to exports in production
- Fixed padding below truncated title of event cards
- Fixed exports that weren't enabled in Docker
- Fixed error page when event end date is null

## 2.0.0-rc.2 - 2021-11-22

This lists changes since 2.0.0-rc.1. Please read the [UPGRADE.md](https://framagit.org/framasoft/mobilizon/-/blob/main/UPGRADE.md#upgrading-from-13-to-20) file as well.

### Changed

- Improve MyEvents page description text

### Fixed

- Fix spacing in organizer picker
- Increase number of close events and follow group events
- Fix accessing user profile in admin section
- Set initial values for some EventMetadata elements, fixing submitting them right away with no value
- Avoid giving an error page if the apollo futureParticipations query is undefined

### Translations

- German
- Hungarian

## 2.0.0-rc.1 - 2021-11-20

This lists changes since 2.0.0-beta.2. Please read the [UPGRADE.md](https://framagit.org/framasoft/mobilizon/-/blob/main/UPGRADE.md#upgrading-from-13-to-20) file as well.

### Changed

- Mention following groups on the registration page
- Add missing group name to activity notifications
- Warn while registering and logging when the email contains uppercase characters
- Improve json-ld metadata on event live streams
- Add "eventAttendanceMode" to JSON-ld schema.org event representation
- Improve sending pending participation notifications
- Add "formerType" and "delete" attributes on Tombstones ActivityPub objects representation

### Fixed

- Fixed creating group activities when creating events with some fields
- Move release package at correct path for CI upload
- Fixed event contacts that were not exposed and fetched over federation
- Don't sign fetch when fetching actor for a given signature
- Some various HTTP signatures issues
- Fixed actor AP representation of avatar
- Handle errors when fetching actor pictures
- Fixed sending group events to followers on Mastodon
- Fixed actors avatars and banners being deleted if the same file was also an orphan media

### Translations

- Gaelic
- Spanish

## 2.0.0-beta.2 - 2021-11-15

This lists changes since 2.0.0-beta.1. Please read the [UPGRADE.md](https://framagit.org/framasoft/mobilizon/-/blob/main/UPGRADE.md#upgrading-from-13-to-20) file as well.

### Added

- Group followers and members get an notification email by default when a group publishes a new event (subject to activity notification settings)
- Group admins can now approve or deny new memberships
- Added organizer actor name (profile or group) in the icalendar export
- Add initial support for federation with Gancio

### Changed

- Event update notification is send to participants ~30 minutes after the event update, so that successive edits are throttled.
- Event, post and comments titles and content now have expose their detected language in HTML, for improved screen reader experience

### Fixed

- Release front-end files are no longer in duplicate
- Only show datetime timezone toggle on event if the timezone offset is different from our own
- Fix error when determining audience for Discussion when deleting a comment
- Fix a couple of accessibility issues
- Limit to acceptable tags when pasting raw HTML into comment fields on front-end
- Fixed group map display
- Fixed updating group physical address
- Allow group members to access group drafts
- Improve group refreshment workflow
- Fixed date signature generation for federation
- Fixed an issue when duplicating a group event from another profile
- Fixed event metadata not saved on eventcreation
- Use a different pagination parameter for searched events and featured events on search page

### Translations

- Gaelic
- Spanish

## 2.0.0-beta.1 - 2021-11-09

Please read the [UPGRADE.md](https://framagit.org/framasoft/mobilizon/-/blob/main/UPGRADE.md#upgrading-from-13-to-20) file as well.

### Added

- Added possibility to follow groups and be notified from new upcoming events
- Export list of participants to CSV, `PDF` and `ODS`
- Allow to set timezone for an event. The timezone is automatically defined from the address if one is defined. If the event timezone is different than the user's current one, a toggle is shown to switch between the two.
- Added initial support for Right To Left languages (such as arabic) and [BiDi](https://en.wikipedia.org/wiki/Bidirectional_text)
- Build releases in `arm` and `arm64` format in addition to `amd64`
- Build Docker images in `arm` and `arm64` format in addition to `amd64`
- Added possibility to indicate the event is fully online
- Added possibility to search only for online events
- Added possibility to search only in past events
- Detect event, comments and posts languages automatically. Allows setting language
- Allow to change an user's password through the users.modify mix task
- Add instance setting so that only the admin can create groups
- Add instance setting so that only groups can create events
- Added JSON-LD metadata about the event in emails
- Added a quick link to email notification settings at the bottom of emails
- Allow to access Mobilizon with a specific language directly by using `https://instance.tld/lang` where `lang` is a language supported by Mobilizon

### Changed

- Multiple UI improvements, including post, event and participation cards, discussions and emails. The « My Events » page was also redesigned to allow showing events from your groups.
- Various accessibility improvements
- Delete current actor ID as well from local storage when unlogging
- Show a default text for instance contact in default terms text when no instance contact is set
- Only show locatecontrol button in leaflet map when we can do geolocation
- Disable push column in notification settings when push is not available
- Show actual language instead of language code in Users admin view
- Empty old & new passwords fields when successful password change
- Don't link to the group page from admin when actor is suspended
- Warn participants when the event organizer is suspended (and therefore the event cancelled)
- Improve metadata on public page
- Make sure some event action pages (participate remotely or without an account) don't get indexed by search engines
- Only send `Tombstone` element in `Delete` activities, not the whole previous deleted element.
- Make sure `Delete` activity are send correctly to everyone
- Only add address and tags to event icalendar export if they exist
- `master` branch has been renamed to `main`

### Removed

- Support for Elixir < 1.12 and OTP < 22

### Fixed

- Fix tags autocomplete
- Fix config onboarding after LDAP initial connexion
- Fix events pagination on tags page
- Fixed deduplicated files from orphan media being deleted as well
- Fix deleting own account
- Fix search returning user profiles instead of only groups
- Fix federating geo coordinates
- Fix an issue with group activity items when moving resources
- Fix an issue with Identity Picker
- Fix an issue with TagInput
- Fix an issue when leaving a group
- Fix admin settings edition
- Fix an issue when showing public page of suspended group
- Removed non existing page (`/about/mobilizon`) from sitemap
- Fix action logs containing group suspension events
- Fixed group physical address not exposed to ActivityPub

### Security

- Fixed private messages sent as event replies from Mastodon that were shown publically as public comments. They are now discarded.

### Translations

- Czech
- Gaelic
- German
- Indonesian
- Norwegian Nynorsk
- Occitan
- Persian
- Portuguese (Brazil)
- Russian
- Slovenian
- Spanish

## 1.3.2 - 2021-08-23

### Fixed

- Fixed deduplicated files from orphan media being cleanup as well
- Fixed config onboarding after initial connection
- Fixed current actor ID not being deleted from localstorage after logout
- Fixed missing pagination on tag exploring page
- Fixed deleting own account
- Fixed user profiles that could show up in group search
- Fixed accessibility issues on the account settings page

## 1.3.1 - 2021-08-20

### Fixed

- Fixed default listen IP and sitemap creation for Docker configurations
- Fixed issues related to user timezone setting being shown as set when it wasn't, leading to timezone sometimes missing and causing issues (#746, #815)
- Fixed issues with managing resources (#837, #838)

### Translations

- Gaelic
- Finnish
- Spanish

## 1.3.0 - 2021-08-17

### Added

- **Allow remote group moderators to edit group events and posts**
- **Allow events to hold metadata information, either preconfigured (live video URL, price details, accessibility informations,…), either through a free key/value form.** Metadata concerning live video feeds linking to PeerTube, YouTube & Twitch will benefit from iframe integration.
- Add the possibility to create profiles and groups from CLI
- Add the possibility to create a profile at the same time when creating an user from CLI
- Add the possibility to create users with LDAP provider from CLI
- Added back support for Docker-compose based development
- Added rel=canonical and meta robots noindex tags to public pages from remote groups, in order to avoid them being indexed by Google
- Allow members-restricted posts to be viewable by instance moderators (for moderation purposes)
- Added a filter to resize pictures bigger than 1920x1080
- Allow to deny registration by email or email domain
- Added missing index on participants url
- Added a loading wheel to show that events are loading on some views

### Changed

- Made server only listen on IPv4 in the install template
- Improve identity picker to have a fixed height and allow filtering between your identities and group contacts
- Leaflet map controls (zoom/locate) are now translatable
- Show exactly 12 events on the Explore page

### Fixed

- Fixed links contained in event & post description that didn't open in new tabs
- Add back missing RSS/ical links on public group pages
- Fixed links to Framacolibri forum
- Fixed drafts and restricted visibility events & posts listed on group page
- Fixed notification page on Safari
- Fixed profile edition
- Fixed Feed Token recreation
- Fixed media cleaner job
- Fixed english being always used as a language instead of the default one set when the request has no `Accept-Language` header (such as Google index bots)
- Fixed Ecto validation errors not being translated and interpolated
- Fixed <html> `lang` attribute not being properly set with the language currently used
- Fixed federated posts having wrong visibility setting
- Fixed unused CSS filter on homepage rendering wrong on Webkit
- Fixed handling SSL being already started in LDAP connection
- Fixed an Apollo cache issue when registrering your first profile
- Fixed the Docker image missing ca-certificates
- Fixed missing pagination on Explore page featured events
- Fixed broken popup warning when editing an event
- Fixed GraphQL Playground (again)
- Fixed Coordinates mixmatch between latitude and longitude in iCalendar export and federation
- Fixed token refreshment issues
- Fixed search from 404 page

### Translations

- Catalan
- Chinese (Traditional)
- Finnish
- French
- Gaelic
- Galician
- German
- Indonesian
- Russian
- Spanish

## 1.2.3 - 2021-07-02

### Changed

- Improved list discussion items UI on the group panel

### Fixed

- Fixed 'unsafe-inline' being in CSP
- Fixed group discussions with deleted comments

## 1.2.2 - 2021-07-01

### Changed

- Improved UI for participations when message is too long

### Fixed

- Fixed pictures without metadata information in post display
- Fixed crash when trying to notify activities not from groups
- Fixed imagemagick missing from Dockerfile
- Fixed push notifications for group, members & post activities
- Fixed ellipsis in DiscussionListView
- Fixed submission button for posts not visible on mobile
- Fixed remote profile suspension

### Translations

- Spanish

## 1.2.1 - 2021-06-29

### Fixed

- Fixed Docker image missing libc (which is required by newer OTP versions at runtime)
- Fixed compatibility check in Notification section for service workers

## 1.2.0 - 2021-06-29

### Added

- **Notifications for various group and event activity, both by email and browser push notifications. Daily and weekly digests are also available.**
- Possibility for an event organizer to announce a (public) comment, triggering notifications for participants
- Add a snackbar message to manually reload the UI when updates are available
- Add blurhash support for some banners
- Added basic metadata (start time & physical address) in the opengraph preview

### Changed

- **Interface improvements to events, comments, homepage and group pages**
- **Various improvements to mobile views**
- Make JWT access tokens short-lived
- Disabled Cldr warning that the `Cldr.Plug.AcceptLanguage` plug didn't many any known locale
- Replaced GraphiQL web interface with graphql-playground

### Removed

- Internet Explorer and other older browsers support. This allows us to provide lighter builds.

### Fixed

- Fixed compatibility for previous OTP versions
- Fixed the "member joined" activity event not being displayed in the group activity timeline
- Fixed relay and anonymous actor telling they automatically approve followers
- Fixed mix tasks showing output from all error levels
- Fixed missing metadata on some pages
- Fixed some config values being defined at compile-time instead of runtime
- Fixed missing pagination for group resources
- Fixed missing `.ics` suffix for email event attachments
- Fixed missing unique index on posts URL
- Fixed creating events from group page not always auto-selecting the correct organizer actor
- Fixed error when deleting actor with type different from Person or Group
- Fixed not defaulting to UTC timezone when user has no tz setting in their activity recaps
- Fixed Sentry loading itself even if not configured
- Fixed showing proper message when anonymous participation was confirmed but just wasn't saved in browser
- Fixed editing some event properties
- Fixed group image ratio in admin dashboard
- Fix GraphiQL CSP headers

### Translations

- Finnish
- French
- Galician
- Italian
- Occitan
- Russian
- Spanish
- Swedish

## 1.2.0-beta.3 - 2021-06-27

### Added

- Allow sending notifications to event organizer when new comment is posted
- Allow sending comment announcements notifications to anonymous participants as well

### Changed

- Disabled Cldr warning that the `Cldr.Plug.AcceptLanguage` plug didn't many any known locale

### Fixed

- Fixed error when deleting actor with type different from Person or Group
- Fixed not defaulting to UTC timezone when user has no tz setting in their activity recaps
- Fixed Sentry loading itself even if not configured
- Fixed showing proper message when anonymous participation was confirmed but just wasn't saved in browser
- Fixed editing some event properties

### Translations

- Persian (New!)
- Spanish

## 1.2.0-beta.2 - 2021-06-26

### Added

- Added basic metadata (start time & physical address) in the opengraph preview
- Made mentions trigger notifications
- Allow to send activity digests
- Mix task to generate web push keypair

### Fixed

- Fixed missing unique index on posts URL
- Fixed creating events from group page not always auto-selecting the correct organizer actor

### Translations

- French
- Spanish

## 1.2.0-beta.1 - 2021-06-21

### Added

- **Notifications for various group and event activity, both by email and browser push notifications**
- Possibility for an event organizer to announce a (public) comment, triggering notifications for participants
- Add a snackbar message to manually reload the UI when updates are available
- Add blurhash support for some banners

### Changed

- **Interface improvements to events, comments, homepage and group pages**
- **Various improvements to mobile views**
- Make JWT access tokens short-lived

### Removed

- Internet Explorer and other older browsers support. This allows us to provide lighter builds.

### Fixed

- Fixed compatibility for previous OTP versions
- Fixed the "member joined" activity event not being displayed in the group activity timeline
- Fixed relay and anonymous actor telling they automatically approve followers
- Fixed mix tasks showing output from all error levels
- Fixed missing metadata on some pages
- Fixed some config values being defined at compile-time instead of runtime
- Fixed missing pagination for group resources
- Fixed missing `.ics` suffix for email event attachments

### Translations

- Finnish
- Galician
- Italian
- Occitan
- Russian
- Spanish
- Swedish

## 1.1.4 - 2021-05-19

### Fixes

- Fixes rich media parsers, so that some resource links work again
- Fixes some depreciated calls that were removed in OTP24
- Fixes groups not being refreshed after joining a group
- Fixes the notice that is shown when joining a group that the content may not be available right away - because the group is remote - being shown everytime, even when the group is local
- Fixes OGP image not being defined for posts

### Translations

- French
- Galician
- Italian

## 1.1.3 - 2021-05-03

### Changed

- Lower the frequency for refreshment of external groups

### Fixes

- Fixed spaces being eaten in the rich text editor (event description, comments and public posts)
- Fixed event physical address display
- Fixed tags being limited to 20 characters
- Fixed some ActivityPub errors

### Translations

- Galician
- Russian
- Spanish

## 1.1.2 - 2021-04-28

### Changed

- Added an unique index on the addresses url
- Added org.opencontainers.image.source annotation to the Docker image
- Improved the moderation action logs interface

### Fixes

- **Fixed some invalid email headers**
- **Fixed and repaired default profile still pointing on deleted profile**
- Fixed some ActivityPub issues and improve error handling
- Fixed a duplicate sentence in the email changed html template
- Fixed resource metadata remote image URL
- Fixed not only remote groups being refreshed after the acceptation of an invite
- Fixed an UI overflow on the organizer metadata block if the organizer remote username is too long

### Translations

- Italian
- German
- Slovenian
- Russian

## 1.1.1 - 2021-04-22

### Changed

- Allow to remove user location setting and location information on an event or group
- Instance level feeds are now shown on the instance About page, and are exposed as `rel=alternate` links, if instance level feeds are activated in the config
- Webfinger module now queries the host-meta XRD endpoint to detect the webfinger well-known endpoint
- Instance maximum upload sizes are now exposed in the API
- Improve handling of media files which are too heavy
- Improve details when editing or showing an user through CLI
- More strict browser compatibility
- Renamed "Close events" to "Nearby events" ("close" is too close to "closed")
- Improved Sentry integration

### Fixes

- Fixed accessing a group discussion page without being a member (the page was just broken)
- Fixed reloading the members list after excluding a member
- Fixed comments being closed under an event message when not connected
- Fixed path issue when fetching favicon for resources
- Fixed content type and size missing for profile avatars
- Fixed HTTP clients user-agent not using runtime configuration
- Fixed the `support` folder not being copied into releases
- Fixed the participation button position when text is too long or in some cases
- Fixed the incorrect CSP configuration
- Fixed discussions being sent to followers instead of members
- Fixed showing broken public UI for deleted/suspended group
- Fixed warning when getting out of creating/editing an unsaved event that was broken for some languages
- Fixed addresses being not trimmed in the iCalendar exports
- Fixed editing an user's email in CLI
- Fixed suspended actors being refreshed

### Translations

- Gaelic
- German
- Kabyle (New!)
- Norwegian
- Russian
- Slovenian
- Spanish

## 1.1.0 - 2021-03-31

This version introduces a new way to install and host Mobilizon : Elixir releases. This is the new default way of installing Mobilizon. Please read [UPGRADE.md](./UPGRADE.md#upgrading-from-10-to-11) for details on how to migrate to Elixir binary releases or stay on source install.

### Added

- **Add a group activity logbook**
- **Possibility for user to define a location in their settings to get close events**
- **Support for Elixir releases and runtime.exs, allowing to change configuration without recompiling**
- Support for Sentry
- Added support for custom plural rules on front-end (only Gaelic supported for now)
- Added possibility to bookmark search by location through geohash
- Add ENV parameter to allow Docker users to specify the IP which Mobilizon listens on
- Add instance-wide ICS & Atom feeds of public events (disabled by default)
- Add user and profile secret (tokened) feeds
- Runit configuration files

### Changed

- Prune done background jobs
- Improved search form
- Improved backend error page
- Added a confirmation step before deleting a conversation
- The default configuration for Mobilizon now listens only on the local interface
- Creating an event from the group page configures the event creation interface with the group as organizer
- Only provide executables for unix

### Removed

- Support for Elixir versions < 1.11

### Fixes

- Fixed editing a group discussion
- Fixed accessing terms and privacy pages
- Fixed refreshing only groups which are stale
- Fixed success message when validating group follower
- Fixed formatted dates using system locale instead of browser/Mobilizon's locale
- Fixed federating draft status
- Fixed group draft posts being sent to followers
- Fixed detecting membership status on group page
- Fixed admin language selection
- Fixed geospatial configuration only being evaluated at compile-time, not at runtime
- Handle ActivityPub Fetcher returning text that's not JSON
- Fix accessing a group profile when not a member
- Fixed accessing the homepage with no location setting defined
- Fixed location field not showing in preferences if setting not already set
- Fixed lasts events published order on the homepage
- Fixed a typo in range/radius showing the wrong radius for close events on homepage
- Fixed hashtags disappearing from content
- Fixed close events order
- Fixed group posts edition
- Fixed validating new email with bad token
- Fixed `.well-known/host-meta` not being accessible with correct `Accept` header
- Fixed posts default publish date overriding remote ones
- Fixed getting a page description in some cases when creating a resource
- Fixed getting metadata from tweets when creating a resource
- Fixed bad handling of duplicate usernames
- Fixed handling of bad URIs to proxify
- Fixed creating discussion with title containing only spaces
- Fixed registering new user account with same email as unconfirmed
- Fixed handling changing default actor unlogged
- Fixed handling getting organized events from an actor when not authorized
- Fixed empty comments being allowed
- Fixed the number of group followers per page
- Fixed issue when selecting a location in your settings
- Fixed group feeds not showing when you are a member of the group
- Fixed handling feeds with unknown format
- Fixed a couple of issues when viewing a remote group
- Fixed issues with the attributed organizer when creating an event
- Fixed HTML entities not being decoded in icalendar exports and feeds
- Fixed instance follows being auto-approved
- Fixed parsing the IP from the MOBILIZON_INSTANCE_LISTEN_IP env variable for Docker
- Fixed release startup in Docker container

### Translations

- Arabic
- Belarusian
- Bengali
- Catalan
- Chinese (Traditional)
- English
- French
- Gaelic **New!**
- Galician
- German
- Hungarian
- Italian
- Occitan
- Polish
- Portuguese (Brazil)
- Russian
- Slovenian
- Spanish

## 1.1.0-rc.3 - 2021-03-30

### Changed

- Only provide executables for unix

### Fixed

- Fixed parsing the IP from the MOBILIZON_INSTANCE_LISTEN_IP env variable for Docker
- Fixed release startup in Docker container

## 1.1.0-rc.2 - 2021-03-30

### Added

- Runit configuration files

### Fixed

- Fixed the number of group followers per page
- Fixed issue when selecting a location in your settings
- Fixed group feeds not showing when you are a member of the group
- Fixed handling feeds with unknown format
- Fixed a couple of issues when viewing a remote group
- Fixed issues with the attributed organizer when creating an event
- Fixed HTML entities not being decoded in icalendar exports and feeds
- Fixed instance follows being auto-approved

### Translations

- Galician
- German
- Hungarian
- Russian
- Spanish

## 1.1.0-rc.1 - 2021-03-29

### Added

- Add ENV parameter to allow Docker users to specify the IP which Mobilizon listens on
- Add instance-wide ICS & Atom feeds of public events (disabled by default)
- Add user and profile secret (tokened) feeds

### Changed

- The default configuration for Mobilizon now listens only on the local interface
- Creating an event from the group page configures the event creation interface with the group as organizer

### Fixed

- Fixed hashtags disappearing from content
- Fixed close events order
- Fixed group posts edition
- Fixed validating new email with bad token
- Fixed `.well-known/host-meta` not being accessible with correct `Accept` header
- Fixed posts default publish date overriding remote ones
- Fixed getting a page description in some cases when creating a resource
- Fixed getting metadata from tweets when creating a resource
- Fixed bad handling of duplicate usernames
- Fixed handling of bad URIs to proxify
- Fixed creating discussion with title containing only spaces
- Fixed registering new user account with same email as unconfirmed
- Fixed handling changing default actor unlogged
- Fixed handling getting organized events from an actor when not authorized
- Fixed empty comments being allowed

### Translations

- Gaelic
- Galician
- German
- Hungarian
- Italian
- Polish
- Portuguese (Brazil)
- Russian
- Slovenian
- Spanish

## 1.1.0-beta.6 - 2021-03-17

### Fixed

- Fixed a typo in range/radius showing the wrong radius for close events on homepage

## 1.1.0-beta.5 - 2021-03-17

### Fixed

- Fixed a typo in range/radius preventing close events from showing up

## 1.1.0-beta.4 - 2021-03-17

### Fixed

- Fixed accessing the homepage with no location setting defined
- Fixed location field not showing in preferences if setting not already set
- Fixed lasts events published order on the homepage

## 1.1.0-beta.3 - 2021-03-16

### Fixed

- Handle ActivityPub Fetcher returning text that's not JSON
- Fix accessing a group profile when not a member

## 1.1.0-beta.2 - 2021-03-16

### Fixed

- Fixed geospatial configuration only being evaluated at compile-time, not at runtime

### Translations

- Slovenian

## 1.1.0-beta.1 - 2021-03-10

This version introduces a new way to install and host Mobilizon : Elixir releases. This is the new default way of installing Mobilizon. Please read [UPGRADE.md](./UPGRADE.md#upgrading-from-10-to-11) for details on how to migrate to Elixir binary releases or stay on source install.

### Added

- **Add a group activity logbook**
- **Possibility for user to define a location in their settings to get close events**
- **Support for Elixir releases and runtime.exs, allowing to change configuration without recompiling**
- Support for Sentry
- Added support for custom plural rules on front-end (only Gaelic supported for now)
- Added possibility to bookmark search by location through geohash

### Changed

- Prune done background jobs
- Improved search form
- Improved backend error page
- Added a confirmation step before deleting a conversation

### Removed

- Support for Elixir versions < 1.11

### Fixes

- Fixed editing a group discussion
- Fixed accessing terms and privacy pages
- Fixed refreshing only groups which are stale
- Fixed success message when validating group follower
- Fixed formatted dates using system locale instead of browser/Mobilizon's locale
- Fixed federating draft status
- Fixed group draft posts being sent to followers
- Fixed detecting membership status on group page
- Fixed admin language selection

### Translations

- Arabic
- Belarusian
- Bengali
- Catalan
- Chinese (Traditional)
- English
- French
- Gaelic
- Galician
- German
- Hungarian
- Italian
- Occitan
- Portuguese (Brazil)
- Slovenian
- Spanish
- Russian

## 1.0.7 - 2021-02-27

### Fixed

- Fixed accessing group event unlogged
- Fixed broken redirection with Webfinger due to strict connect-src
- Fixed editing group discussions
- Fixed search form display
- Fixed wrong year in CHANGELOG.md

## 1.0.6 - 2021-02-04

### Added

- Handle frontend errors nicely when mounting components

### Fixed

- Fixed displaying a remote event when organizer is a group
- Fixed sending events & posts to group followers
- Fixed redirection after deleting an event

## 1.0.5 - 2021-01-27

### Fixed

- Fixed duplicate entries in search with empty search query

## 1.0.4 - 2021-02-26

### Added

- **Added interface to approve/reject group follow requests**
- **Added UI for group public RSS (Atom) / ICS feeds**
- **Attach ICS files representing the event to notifications and participations emails**
- Add initial support to build Elixir releases
- Add some CSP & other security headers

### Changed

- Added `<hr>` to allowed HTML tags
- Events are now correctly ordered by their beginning date on search and group page
- Improve resource metadata parsing by restricting OGP/Twitter metadata to an allowed list of attributes
- Reverse proxy pictures from resource metadata (favicons & such)

### Fixed

- **Fixed group remote subscription**
- Upgrade PWA support library to avoid a call to Google CDN
- Fixed group avatar & banner upload
- Fixed some events not showing on homepage
- Fixed the `next` and `prev` attribute not being present in `CollectionPage` ActivityPub Collections
- Added a text to explain that group discussions are restricted to members on discussion list page
- Fixed ICS export timezone issues
- Fixed remote interactions when the content was not local to the instance
- Fixed a federation issue with group member removal
- Hide event organiser profile through the GraphQL API when a group is the organizer
- Fix an issue where the event form datepickers where displayed under the address map

### Translations

- Bengali (New!)
- Catalan
- Finnish
- French
- Galician
- German
- Italian
- Norwegian
- Polish
- Portuguese (New!)
- Slovenian (New!)
- Spanish
- Swedish

## 1.0.3 - 2020-12-18

**This release adds new migrations, be sure to run them before restarting Mobilizon**

**This release has repair steps, be sure to execute them right after restarting Mobilizon**

### Special operations

- **Reattach media files to their entity.**
  When media files were uploaded and added in events and posts bodies, they were only attached to the profile that uploaded them, not to the event or post. This task attaches them back to their entity so that the command to clean orphan media files doesn't remove them.

  - Source install
    `MIX_ENV=prod mix mobilizon.maintenance.fix_unattached_media_in_body`
  - Docker
    `docker-compose exec mobilizon mobilizon_ctl maintenance.fix_unattached_media_in_body`

- **Refresh remote profiles to save avatars locally**
  Profile avatars and banners were previously only proxified and cached. Now we save them locally. Refreshing all remote actors will save profile media locally instead.

  - Source install
    `MIX_ENV=prod mix mobilizon.actors.refresh --all`
  - Docker
    `docker-compose exec mobilizon mobilizon_ctl actors.refresh --all`

- **imagemagick and webp are now a required dependency** to build Mobilizon.
  Optimized versions of Mobilizon's pictures are now produced during front-end build.
  See [the documentation](https://docs.joinmobilizon.org/administration/dependencies/#misc) to make sure these dependencies are installed.

### Added

- **Add a command to clean orphan media files**. There's a `--dry-run` option to see what files would have been deleted.  
  **Make sure all media files have been reattached properly (see above) before running this command.**  
  In 1.1.0 a scheduled job will be enabled to clear orphan media files automatically after a while.
- Added user and actors media usage information in administration
- Added a scheduled job to clean unconfirmed users (and their eventual initial profile) after a 48 hour grace period
- Added a mix task to manually clean unconfirmed users
- Added OpenStreetMap (OSRM) or GoogleMaps routing pages on the event map modal
- Added PWA support, Mobilizon can now be installed on Android (Firefox and Chrome), iOS (Safari) and desktop (Chrome)
- Added possibility to pick language through a setting on the footer for unlogged users

### Changed

- Save remote avatars and banners instead of proxifying them
- Forbid creating usernames with uppercase characters
- Allow LDAP admin to use a fully qualified DN (different than the one for the users)
- Allow LDAP users to be filtered by LDAP attribute `memberOf`.
- Improve the "My events" and "My groups" page when there's nothing here yet
- Show identity concerned when listing event participations (in "My events") and group membership (in "My groups")
- The datetime picker on the event's edition page has been changed and allows directly editing the text
- Allow to clear and remove pictures from events and posts

### Fixed

- Fixed inline media that weren't being tracked, so that they are not considered orphans media files.
- Fixed permissions on the Docker volume
- Fixed emails not using user timezone
- Fixed draft status not being shown on group events & posts inside admin section
- Fixed cancelled status not being shown on cancelled events cards
- Fixed membership notification emails not being sent with the user's language
- Fixed group posts ActivityPub endpoint
- Fixed unlisted groups being available in search
- Fixed inline media pictures being unattached when editing an event or a post
- Fixed adding an instance to follow with spaces
- Fixed past groups showing up on group's page
- Fixed error message not showing up when you are already an anonymous participant for an event
- Fixed error message not showing up when you pick an username already in user for a new profile or a group
- Fixed translations not fallbacking properly to english when not found
-

### Security

- Stop logging user JWT tokens in Websocket Mobilizon logs

### Translations

Updated translations:

- Catalan
- Dutch
- English
- Finnish
- French
- Galician
- German
- Hungarian
- Italian
- Norwegian
- Occitan
- Polish
- Spanish
- Swedish

## 1.0.2 - 2020-11-15

**This release adds new migrations, be sure to run them before restarting Mobilizon**

### Changed

- PostgreSQL extensions creations are now automatically handled in the Docker's entrypoint

### Fixed

- Fixed an issue with Oban migrations and some PostgreSQL versions
- Fixed an issue that causes email not being able to be sent when the `TZ` environment variable is not available
- Fixed 3rd-party login Ueberauth providers not being usable if configured at runtime

### Translations

- Catalan
- Hungarian
- Italian
- Occitan

## 1.0.1 - 2020-11-14

**This release adds new migrations, be sure to run them before restarting Mobilizon**

### Added

- **Possibility to join open groups** (local and remote). Possibility in the group settings to pick if the group is open to new members or not.
  Note: The group default setting is closed. You need to manually set your group as open in the group settings.
- **Docker support** (@Pascoual). See [documentation](https://docs.joinmobilizon.org/administration/docker/)
- Added steps to the onboarding process on first login, including a profile and federation presentation step
- Added a regular job to refresh remote groups once in a while

### Changed

- Adapted the demo mode to reflect changes (Mobilizon is no longer in beta)
- User language is now saved in localStorage (allowing to load the right locale right away, and in the future allowing to pick custom language without account https://framagit.org/framasoft/mobilizon/-/issues/375)

### Fixed

- Fixed group list, group members and instance followers/followings pagination
- Fixed detecting file MIME type if the file hasn't got a filename
- Changed a few sentences that didn't sounded english (@mkljczk)
- Fixed instance custom privacy policy not being applied
- Fixed demo warning always displaying on the text version of emails
- Fixed language picker not loading languages and saving the preference
- Fixed groups created without collections URLs and added a repair step to add them to local groups where these are missing
- Handle accessing instance followers/followings unlogged
- Made sure we only have a single instance relay actor
- Fixed about page crashing when the instance was configured with languages that Mobilizon doesn't support itself
- Don't allow remote comments under events if the event doesn't allow comments
- Fixed notification settings not displaying as saved
- Fixed pictures not being served by `Plug.Static`
- Fixed emails missing `Date` and `Message-ID` headers
- Fixed onboarding not saving language/timezone/notification settings

### Translations

- Basque
- Catalan
- Esperanto
- Finnish
- French
- Galician
- German
- Hungarian
- Italian
- Kannada
- Occitan
- Norwegian Nynorsk
- Polish
- Spanish

## 1.0.0 - 2020-10-26

### Changed

- Strengthen upload picture and filter code and tests
- Add link to mobilizon.org on the bottom of the about page to register

### Fixed

- Fix several front-end routes being accessible without authentification and make them redirect to login page (no information was given, the pages were just empty)
- Fallback version code to Mix project version value if there's no Git information
- Fix identity avatar change flicking or showing wrong avatar for identity
- Fix public group page when description/list of events/list of posts are empty
- Make sure `"to"` and `"cc"` in ActivityStreams are always lists (@vpzomtrrfrt)
- Check port when comparing URLs (@vpzomtrrfrt)

### Translations

- Galician
- German
- Occitan
- Spanish

## 1.0.0-rc.4 - 2020-10-22

### Fixed

- Fix an issue with group event listing

## 1.0.0-rc.3 - 2020-10-22

### Added

- Task to refresh a remote instance (crawling their outbox, fetching their latest public events just in case of federation issues)
- New homepage with illustration

### Fixed

- Handle timezone not detected inside browser
- Fix webfinger not following redirections
- Fix some Apollo GraphQL errors
- Disable updating/deleting group posts and discussions for non-moderators
- Fix group drafts events showing up on group public page

## 1.0.0-rc.2 - 2020-10-20

### Added

- Show if user is disabled in [`mix mobilizon.users.show` task](https://docs.joinmobilizon.org/administration/CLI%20tasks/manage_users/#show-an-users-details)
- Improved [ActivityPub documentation](https://docs.joinmobilizon.org/contribute/activity_pub/), especially for group federation.
- Show instance languages on instance about page
- Add fancy pictures on footer and 404 page

### Changed

- The [`mix mobilizon.users.delete` task](https://docs.joinmobilizon.org/administration/CLI%20tasks/manage_users/#delete-an-user) behaviour completely deletes the user, unless the `--keep_email` option is given (can be used to prevent someone registering again with the same email).
- Deleting your own account completely deletes user information (it previously kept the email information).
- The administration dashboard now shows more information on local events, groups and followed/following instances

### Fixed

- Significantly improve front-end build times and build in modern mode (with ES modules). The front-end payload is also quite lighter (loads each view asynchronously)
- Don't count deactivated/suspended users in public statistics
- Fix account settings for 3rd-party auth users
- Disable sending reset password emails to disabled users
- Fix display of event edit page on mobile
- Fix events from former followed instances showing up on explore page or in search
- The member management has received a couple fixes
- Handle issue when nothing was found when doing a reverse geocode (when drag&dropping the marker on map)
- Fix issue when searching by username with our own domain
- Fix issue with wrong redirection for remote groups when deleting a post
- Make sure only group moderators (and higher) can update/delete group events and group posts.
- Fix OEmbed preview generator parser
- Fix an issue with hostname validator in preview generator

### Translations

- Spanish
- Galician

## 1.0.0-rc.1 - 2020-10-12

### Special operations

- We added `application/ld+json` as acceptable MIME type for ActivityPub requests, so you'll need to recompile the `mime` library we use before recompiling Mobilizon:

  ```
  MIX_ENV=prod mix deps.clean mime --build
  ```

- The [nginx configuration](https://framagit.org/framasoft/mobilizon/-/blob/main/support/nginx/mobilizon.conf) has been changed with improvements and support for custom error pages.

- The cmake dependency has been added (see [our documentation](https://docs.joinmobilizon.org/administration/dependencies/#basic-tools))

### Added

- Possibility to login using LDAP
- Possibility to login using OAuth providers
- Enabled group features in production mode
  - including posts (that can be public, unlisted, or restricted to your group members)
  - resources (collections of links, with folders, accessible to your group members)
  - discussions (group private and organized chats)
  - group events (events can be published by groups - and show some event members as contacts)
  - roles for members (member, moderator, administrator)
  - admin section to manage (suspend) groups
- Sitemap support (for public content) at `sitemap.xml`
- Searching events and groups with location
- More statistics are exposed through the `statistics` GraphQL query

### Changed

- Completely replaced HTMLSanitizeEx with FastSanitize [!490](https://framagit.org/framasoft/mobilizon/-/merge_requests/490)

### Fixed

- Fixed notification scheduler [!486](https://framagit.org/framasoft/mobilizon/-/merge_requests/486)
- Fixed event title escaping [!490](https://framagit.org/framasoft/mobilizon/-/merge_requests/490)
- Various implements in interface thanks to feedback

### Security

- Fix group settings being accessible and editable by non-group-admins (thx @pigpig for reporting this responsibly)
- Fix events being editable by profiles without permissions (thx @pigpig for reporting this responsibly)

## [1.0.0-beta.3] - 2020-06-24

### Special operations

Config has moved from `.env` files to a more traditional way to handle things in the Elixir world, with `.exs` files.

To migrate existing configuration, you can simply run `mix mobilizon.instance gen` and fill in the adequate values previously in `.env` files (you don't need to perform the operations to create the database).

A minimal file template [is available](https://framagit.org/framasoft/mobilizon/blob/main/priv/templates/config.template.eex) to check for missing configuration.

Also make sure to remove the `EnvironmentFile=` line from the systemd service and set `Environment=MIX_ENV=prod` instead. See [the updated file](https://framagit.org/framasoft/mobilizon/blob/main/support/systemd/mobilizon.service).

### Added

- Possibility to participate to an event without an account (confirmation through email required)
- Possibility to participate to a remote event (being redirected by providing federated identity)
- Possibility to add a note as a participant when event participation is manually validated (required when participating without an account)
- Email notifications for events (one hour before, on the day of the event, each week)
- Email notifications for pending participation approval requests (disabled, directly, at most 1 per hour, at most 1 per day)
- Possibility to change email address for the account
- Possibility to delete your account
- Duplicate an event
- Ability to handle basic administration settings in the admin panel
- Config option to allow anonymous reporting
- Basic user and profile management admin interface to suspend local users or remote profiles
- Default Terms of service and Privacy policies
- As an admin, possibility to add rules and contact information
- Allow user to change language

### Changed

- Configuration handling (see above)
- Improved a bit color theme
- Signature validation also now checks if `Date` header has acceptable values
- Actor profiles are now stale after two days and have to be refetched
- Actor keys are rotated some time after sending a `Delete` activity
- Improved event participations managing interface
- Added physical address change to the list of important changes that trigger event notifications
- Improved public event page

### Fixed

- Fixed URL search
- Fixed content accessed through URL search being public
- Fix event links in some emails

## [1.0.0-beta.2] - 2019-12-18

### Special operations

These two operations couldn't be handled during migrations.
They are optional, but you won't be able to search or get participant stats on existing events if they are not executed.
These commands will be removed in Mobilizon 1.0.0-beta.3.

In order to populate search index for existing events, you need to run the following command (with prod environment):

- `mix mobilizon.setup_search`

In order to move participant stats to the event table for existing events, you need to run the following command (with prod environment):

- `mix mobilizon.move_participant_stats`

### Added

- Federation is active
- Added an interface for admins to view and manage instance followers and followings
- Ability to comment below events
- Implement search engine & service in backend **(read special instructions above)**
- Allow WebP and Gif pics upload
- Optimize uploaded pics
- Make tags clickable, redirecting to search
- Added a websocket API call to check if your participation status has changed
- Add a different welcome message when coming from registration
- Link to participation page from event page when you are an organizer
- Added several mix commands to manage users and view actors (`mix mobilizon.users` and `mix mobilizon.actors`) and their documentation
- Added a demo mode to show or hide instance warning
- Added a config option to whitelist users emails or email domains
- Updated Occitan translations (Quentin)
- Updated French translations (Gavy, Zilverspar, ty kayn, numéro6)
- Updated Swedish translations (Anton Strömkvist, Filip Bengtsson)
- Updated Polish translations (Marcin Mikolajczak)
- Updated Italian translations (AlessiBilos)
- Updated Arabic translations (Butterflyoffire)
- Updated Catalan translations (fadelkon, Francesc)
- Updated Belarusian translations (fadelkon)
- Upgraded frontend and backend dependencies

### Changed

- Move participant stats to event table **(read special instructions above)**
- Limit length (20 characters) and number (10) of tags allowed
- Added some backend changes and validation for field length
- Handle error message difference between user not found and user not confirmed
- Make external links (from URL field and description) open in a new tab with `noopener`
- Improve Docker setup and docs
- Upgrade vue-cli to v4, change the way server params injection is made
- Improve some production ipv6 configuration
- Limited year range in the DatePicker
- Event title is now clickable on cards (Léo Mouyna)
- Also consider the PeerTube `CommentsEnabled` property to know if you can reply to an event

### Fixed

- Fix event URL validation and check if hostname is correct before showing it
- Fix participations stats on the MyEvents page
- Fix event description lists margin
- Clear errors on resend password page (Léo Mouyna)
- End datetime being able to happen before begin datetime (Léo Mouyna)
- Fix issue when activating/deactivating limited places (Léo Mouyna)
- Fix Cypress tests
- Fix contribution guide link and improve contribution guide (Joel Takvorian)
- Improve grammar (Damien)
- Fix recursive alias in systemd unit file (Geno)
- Fix multiline display on participants page
- Add polyfill for IntersectionObserver so that it's usable on relatively old browsers
- Fixed crash on Safari on description input by removing `-apple-system` from font-family
- Improve installation docs (mkljczk)
- Fixed links to contributing and docs (Alex Addams)
- Limit file uploads to 10MB
- Added missing `setup_db.psql` file (Geno)
- Fixed docker setup when using non-GNU make (JohanBaskovec)
- Fixed actors deletion that didn't cascade to followers
- Reduced datetime picker input width
- Clear ActivityPub cache when content is updated or deleted
- Fix HTTP signatures not checked for relay inbox
- Handle actor or object being AP Public string (for Mastodon relay subscriptions)
- Fixed Mastodon relay instances subscriptions being shown as users
- Fixed an issue when accessing "My Account"
- Fixed pagination for followers/followings page
- Fixed event HTML representation when `GET` request has no `Accept` header

### Security

- Sanitize event title to avoid XSS

## [1.0.0-beta.1] - 2019-10-15

### Added

- Initial release
