export const configMock = {
  data: {
    config: {
      __typename: "Config",
      anonymous: {
        __typename: "Anonymous",
        actorId: "1",
        eventCreation: {
          __typename: "AnonymousEventCreation",
          allowed: false,
          validation: {
            __typename: "AnonymousEventCreationValidation",
            captcha: {
              __typename: "AnonymousEventCreationValidationCaptcha",
              enabled: false,
            },
            email: {
              __typename: "AnonymousEventCreationValidationEmail",
              confirmationRequired: true,
              enabled: true,
            },
          },
        },
        participation: {
          __typename: "AnonymousParticipation",
          allowed: true,
          validation: {
            __typename: "AnonymousParticipationValidation",
            captcha: {
              __typename: "AnonymousParticipationValidationCaptcha",
              enabled: false,
            },
            email: {
              __typename: "AnonymousParticipationValidationEmail",
              confirmationRequired: true,
              enabled: true,
            },
          },
        },
        reports: {
          __typename: "AnonymousReports",
          allowed: false,
        },
      },
      auth: {
        __typename: "Auth",
        ldap: false,
        oauthProviders: [],
      },
      countryCode: "fr",
      demoMode: false,
      description: "Mobilizon.fr est l'instance Mobilizon de Framasoft.",
      features: {
        __typename: "Features",
        eventCreation: true,
        groups: true,
        koenaConnect: false,
      },
      geocoding: {
        __typename: "Geocoding",
        autocomplete: true,
        provider: "Elixir.Mobilizon.Service.Geospatial.Pelias",
      },
      languages: ["fr"],
      location: {
        __typename: "Lonlat",
        latitude: 48.8717,
        longitude: 2.32075,
      },
      maps: {
        __typename: "Maps",
        tiles: {
          __typename: "Tiles",
          attribution: "© The OpenStreetMap Contributors",
          endpoint: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
        },
        routing: {
          __typename: "Routing",
          type: "OPENSTREETMAP",
        },
      },
      name: "Mobilizon",
      registrationsAllowlist: false,
      registrationsOpen: true,
      resourceProviders: [
        {
          __typename: "ResourceProvider",
          endpoint: "https://lite.framacalc.org/",
          software: "calc",
          type: "ethercalc",
        },
        {
          __typename: "ResourceProvider",
          endpoint: "https://hebdo.framapad.org/p/",
          software: "pad",
          type: "etherpad",
        },
        {
          __typename: "ResourceProvider",
          endpoint: "https://framatalk.org/",
          software: "visio",
          type: "jitsi",
        },
      ],
      slogan: null,
      uploadLimits: {
        __typename: "UploadLimits",
        default: 10_000_000,
        avatar: 2_000_000,
        banner: 4_000_000,
      },
      instanceFeeds: {
        __typename: "InstanceFeeds",
        enabled: false,
      },
    },
  },
};
