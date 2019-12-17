export interface IConfig {
  name: string;
  description: string;

  registrationsOpen: boolean;
  registrationsWhitelist: boolean;
  demoMode: boolean;
  countryCode: string;
  location: {
    latitude: number;
    longitude: number;
    accuracyRadius: number;
  };
  maps: {
    tiles: {
      endpoint: string;
      attribution: string|null;
    },
  };
  geocoding: {
    provider: string;
    autocomplete: boolean;
  };
}
