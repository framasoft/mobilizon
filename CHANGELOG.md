# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.0.6 - 04-02-2020

### Added

- Handle frontend errors nicely when mounting components

### Fixed

- Fixed displaying a remote event when organizer is a group
- Fixed sending events & posts to group followers
- Fixed redirection after deleting an event

## 1.0.5 - 27-01-2020

### Fixed

- Fixed duplicate entries in search with empty search query

## 1.0.4 - 26-01-2020

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

## 1.0.3 - 18-12-2020

**This release adds new migrations, be sure to run them before restarting Mobilizon**

**This release has repair steps, be sure to execute them right after restarting Mobilizon**

### Special operations

* **Reattach media files to their entity.**
  When media files were uploaded and added in events and posts bodies, they were only attached to the profile that uploaded them, not to the event or post. This task attaches them back to their entity so that the command to clean orphan media files doesn't remove them.

  * Source install
    `MIX_ENV=prod mix mobilizon.maintenance.fix_unattached_media_in_body`
  * Docker
    `docker-compose exec mobilizon mobilizon_ctl maintenance.fix_unattached_media_in_body`

* **Refresh remote profiles to save avatars locally**
  Profile avatars and banners were previously only proxified and cached. Now we save them locally. Refreshing all remote actors will save profile media locally instead.

  * Source install
    `MIX_ENV=prod mix mobilizon.actors.refresh --all`
  * Docker
    `docker-compose exec mobilizon mobilizon_ctl actors.refresh --all`

* **imagemagick and webp are now a required dependency** to build Mobilizon.
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

* We added `application/ld+json` as acceptable MIME type for ActivityPub requests, so you'll need to recompile the `mime` library we use before recompiling Mobilizon:
    ```
    MIX_ENV=prod mix deps.clean mime --build
    ```

* The [nginx configuration](https://framagit.org/framasoft/mobilizon/-/blob/master/support/nginx/mobilizon.conf) has been changed with improvements and support for custom error pages.

* The cmake dependency has been added (see [our documentation](https://docs.joinmobilizon.org/administration/dependencies/#basic-tools))

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
