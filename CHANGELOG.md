# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

- Possibility to login using LDAP
- Possibility to login using OAuth providers

### Changed

- Completely replaced HTMLSanitizeEx with FastSanitize [!490](https://framagit.org/framasoft/mobilizon/-/merge_requests/490)

### Fixed

- Fixed notification scheduler [!486](https://framagit.org/framasoft/mobilizon/-/merge_requests/486)
- Fixed event title escaping [!490](https://framagit.org/framasoft/mobilizon/-/merge_requests/490)

## [1.0.0-beta.3] - 2020-06-24

### Special operations
Config has moved from `.env` files to a more traditional way to handle things in the Elixir world, with `.exs` files.

To migrate existing configuration, you can simply run `mix mobilizon.instance gen` and fill in the adequate values previously in `.env` files (you don't need to perform the operations to create the database).

A minimal file template [is available](https://framagit.org/framasoft/mobilizon/blob/master/priv/templates/config.template.eex) to check for missing configuration.

Also make sure to remove the `EnvironmentFile=` line from the systemd service and set `Environment=MIX_ENV=prod` instead. See [the updated file](https://framagit.org/framasoft/mobilizon/blob/master/support/systemd/mobilizon.service).

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
* `mix mobilizon.setup_search`

In order to move participant stats to the event table for existing events, you need to run the following command (with prod environment):
* `mix mobilizon.move_participant_stats`

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
