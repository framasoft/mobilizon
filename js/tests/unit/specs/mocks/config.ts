export const configMock = {
  data: {
    config: {
      anonymous: {
        actorId: "1",
        eventCreation: {
          allowed: false,
          validation: {
            captcha: {
              enabled: false,
            },
            email: {
              confirmationRequired: true,
              enabled: true,
            },
          },
        },
        participation: {
          allowed: true,
          validation: {
            captcha: {
              enabled: false,
            },
            email: {
              confirmationRequired: true,
              enabled: true,
            },
          },
        },
        reports: {
          allowed: false,
        },
      },
      auth: {
        ldap: false,
        oauthProviders: [],
      },
      countryCode: "fr",
      demoMode: false,
      description: "Mobilizon.fr est l'instance Mobilizon de Framasoft.",
      features: {
        eventCreation: true,
        groups: true,
      },
      geocoding: {
        autocomplete: true,
        provider: "Elixir.Mobilizon.Service.Geospatial.Pelias",
      },
      languages: ["fr"],
      location: {
        latitude: 48.8717,
        longitude: 2.32075,
      },
      maps: {
        tiles: {
          attribution: "© The OpenStreetMap Contributors",
          endpoint: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
        },
        routing: {
          type: "OPENSTREETMAP",
        },
      },
      name: "Mobilizon",
      registrationsAllowlist: false,
      registrationsOpen: true,
      resourceProviders: [
        {
          endpoint: "https://lite.framacalc.org/",
          software: "calc",
          type: "ethercalc",
        },
        {
          endpoint: "https://hebdo.framapad.org/p/",
          software: "pad",
          type: "etherpad",
        },
        {
          endpoint: "https://framatalk.org/",
          software: "visio",
          type: "jitsi",
        },
      ],
      slogan: null,
    },
  },
};
