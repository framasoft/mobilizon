# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Special operations
These two operations couldn't be handled during migrations.
They are optional, but you won't be able to search or get participant stats on existing events if they are not executed.
These commands will be removed in Mobilizon 1.0.0-beta.3.

In order to populate search index for existing events, you need to run the following command (with prod environment):
* `mix mobilizon.setup_search`

In order to move participant stats to the event table for existing events, you need to run the following command (with prod environment):
* `mix mobilizon.move_participant_stats`

### Added
- Implement search engine & service in backend **(read special instructions above)**
- Allow WebP and Gif pics upload
- Optimize uploaded pics
- Make tags clickable, redirecting to search
- Add a different welcome message when coming from registration
- Link to participation page from event page when you are an organizer
- Added a warning on login that everything is deleted regularily
- Updated Occitan translations (Quentin)
- Updated French translations (Gavy, Zilverspar, ty kayn)
- Updated Swedish translations (Anton Strömkvist)
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

### Fixed
- Fix event URL validation and check if hostname is correct before showing it
- Fix participations stats on the MyEvents page
- Fix event description lists margin
- Fix Cypress tests
- Fix contribution guide link and improve contribution guide (Joel Takvorian)
- Improve grammar (Damien)
- Fix recursive alias in systemd unit file (Geno)
- Fix multiline display on participants page
- Add polyfill for IntersectionObserver so that it's usable on relatively old browsers
- Fixed crash on Safari on description input by removing `-apple-system` from font-family
- Improve installation docs (mkljczk)
- Limit file uploads to 10MB
- Added missing `setup_db.psql` file (Geno)
- Fixed docker setup when using non-GNU make (JohanBaskovec)
- Fixed actors deletion that didn't cascade to followers

### Security
- Sanitize event title to avoid XSS

## [1.0.0-beta.1] - 2019-10-15
### Added
- Initial release
