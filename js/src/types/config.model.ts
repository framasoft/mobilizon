export interface IConfig {
  name: string;
  description: string;

  registrationsOpen: boolean;
  countryCode: string;
  location: {
    latitude: number;
    longitude: number;
    accuracyRadius: number;
  };
}
