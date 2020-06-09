import gql from "graphql-tag";

export const CONFIG = gql`
  query {
    config {
      name
      description
      registrationsOpen
      registrationsWhitelist
      demoMode
      countryCode
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
        accuracyRadius
      }
      maps {
        tiles {
          endpoint
          attribution
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

export const TIMEZONES = gql`
  query {
    config {
      timezones
    }
  }
`;
