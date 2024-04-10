import gql from "graphql-tag";

export const CONFIG = gql`
  query FullConfig {
    config {
      name
      description
      slogan
      version
      registrationsOpen
      registrationsAllowlist
      demoMode
      longEvents
      countryCode
      languages
      primaryColor
      secondaryColor
      instanceLogo {
        url
      }
      defaultPicture {
        id
        url
        name
        metadata {
          width
          height
          blurhash
        }
      }
      eventCategories {
        id
        label
      }
      anonymous {
        participation {
          allowed
          validation {
            email {
              enabled
              confirmationRequired
            }
            captcha {
              enabled
            }
          }
        }
        eventCreation {
          allowed
          validation {
            email {
              enabled
              confirmationRequired
            }
            captcha {
              enabled
            }
          }
        }
        reports {
          allowed
        }
        actorId
      }
      location {
        latitude
        longitude
        # accuracyRadius
      }
      maps {
        tiles {
          endpoint
          attribution
        }
        routing {
          type
        }
      }
      geocoding {
        provider
        autocomplete
      }
      resourceProviders {
        type
        endpoint
        software
      }
      features {
        groups
        eventCreation
        eventExternal
        antispam
      }
      restrictions {
        onlyAdminCanCreateGroups
        onlyGroupsCanCreateEvents
      }
      auth {
        ldap
        databaseLogin
        oauthProviders {
          id
          label
        }
      }
      uploadLimits {
        default
        avatar
        banner
      }
      instanceFeeds {
        enabled
      }
      webPush {
        enabled
        publicKey
      }
      analytics {
        id
        enabled
        configuration {
          key
          value
          type
        }
      }
      search {
        global {
          isEnabled
          isDefault
        }
      }
      exportFormats {
        eventParticipants
      }
    }
  }
`;

export const CONFIG_EDIT_EVENT = gql`
  query EditEventConfig {
    config {
      timezones
      features {
        groups
      }
      eventCategories {
        id
        label
      }
      anonymous {
        participation {
          allowed
          validation {
            email {
              enabled
              confirmationRequired
            }
            captcha {
              enabled
            }
          }
        }
      }
    }
  }
`;

export const TERMS = gql`
  query Terms($locale: String) {
    config {
      terms(locale: $locale) {
        type
        url
        bodyHtml
      }
    }
  }
`;

export const ABOUT = gql`
  query About {
    config {
      name
      description
      longDescription
      slogan
      contact
      languages
      registrationsOpen
      registrationsAllowlist
      anonymous {
        participation {
          allowed
        }
      }
      version
      federating
      instanceFeeds {
        enabled
      }
    }
  }
`;

export const CONTACT = gql`
  query Contact {
    config {
      name
      contact
    }
  }
`;

export const RULES = gql`
  query Rules {
    config {
      rules
    }
  }
`;

export const PRIVACY = gql`
  query Privacy($locale: String) {
    config {
      privacy(locale: $locale) {
        type
        url
        bodyHtml
      }
    }
  }
`;

export const TIMEZONES = gql`
  query Timezones {
    config {
      timezones
    }
  }
`;

export const WEB_PUSH = gql`
  query WebPush {
    config {
      webPush {
        enabled
        publicKey
      }
    }
  }
`;

export const EVENT_PARTICIPANTS = gql`
  query EventParticipants {
    config {
      exportFormats {
        eventParticipants
      }
    }
  }
`;

export const ANONYMOUS_PARTICIPATION_CONFIG = gql`
  query AnonymousParticipationConfig {
    config {
      anonymous {
        participation {
          allowed
          validation {
            email {
              enabled
              confirmationRequired
            }
            captcha {
              enabled
            }
          }
        }
      }
    }
  }
`;

export const ANONYMOUS_REPORTS_CONFIG = gql`
  query AnonymousParticipationConfig {
    config {
      anonymous {
        reports {
          allowed
        }
      }
    }
  }
`;

export const INSTANCE_NAME = gql`
  query InstanceName {
    config {
      name
    }
  }
`;

export const ANONYMOUS_ACTOR_ID = gql`
  query AnonymousActorId {
    config {
      anonymous {
        actorId
      }
    }
  }
`;

export const UPLOAD_LIMITS = gql`
  query UploadLimits {
    config {
      uploadLimits {
        default
        avatar
        banner
      }
    }
  }
`;

export const EVENT_CATEGORIES = gql`
  query EventCategories {
    config {
      eventCategories {
        id
        label
      }
    }
  }
`;

export const RESTRICTIONS = gql`
  query OnlyGroupsCanCreateEvents {
    config {
      restrictions {
        onlyGroupsCanCreateEvents
        onlyAdminCanCreateGroups
      }
    }
  }
`;

export const GEOCODING_AUTOCOMPLETE = gql`
  query GeoCodingAutocomplete {
    config {
      geocoding {
        autocomplete
      }
    }
  }
`;

export const MAPS_TILES = gql`
  query MapsTiles {
    config {
      maps {
        tiles {
          endpoint
          attribution
        }
      }
    }
  }
`;

export const ROUTING_TYPE = gql`
  query RoutingType {
    config {
      maps {
        routing {
          type
        }
      }
    }
  }
`;

export const FEATURES = gql`
  query Features {
    config {
      features {
        groups
        eventCreation
        eventExternal
        antispam
      }
    }
  }
`;

export const RESOURCE_PROVIDERS = gql`
  query ResourceProviders {
    config {
      resourceProviders {
        type
        endpoint
        software
      }
    }
  }
`;

export const LOGIN_CONFIG = gql`
  query LoginConfig {
    config {
      auth {
        databaseLogin
        oauthProviders {
          id
          label
        }
      }
      registrationsOpen
    }
  }
`;

export const LOCATION = gql`
  query Location {
    config {
      location {
        latitude
        longitude
        # accuracyRadius
      }
    }
  }
`;

export const DEMO_MODE = gql`
  query DemoMode {
    config {
      demoMode
    }
  }
`;

export const LONG_EVENTS = gql`
  query LongEvents {
    config {
      longEvents
    }
  }
`;

export const ANALYTICS = gql`
  query Analytics {
    config {
      analytics {
        id
        enabled
        configuration {
          key
          value
          type
        }
      }
    }
  }
`;

export const SEARCH_CONFIG = gql`
  query SearchConfig {
    config {
      search {
        global {
          isEnabled
          isDefault
        }
      }
    }
  }
`;

export const INSTANCE_LOGO = gql`
  query InstanceLogo {
    config {
      instanceLogo {
        url
      }
    }
  }
`;

export const COLORS = gql`
  query Colors {
    config {
      primaryColor
      secondaryColor
    }
  }
`;

export const DEFAULT_PICTURE = gql`
  query DefaultPicture {
    config {
      defaultPicture {
        id
        url
        name
        metadata {
          width
          height
          blurhash
        }
      }
    }
  }
`;

export const REGISTRATIONS = gql`
  query Registrations {
    config {
      registrationsOpen
      registrationsAllowlist
      auth {
        databaseLogin
      }
    }
  }
`;
