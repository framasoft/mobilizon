import { InstanceTermsType } from "./admin.model";
import { IProvider } from "./resource";

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
  anonymous: {
    participation: {
      allowed: boolean;
      validation: {
        email: {
          enabled: boolean;
          confirmationRequired: boolean;
        };
        captcha: {
          enabled: boolean;
        };
      };
    };
    eventCreation: {
      allowed: boolean;
      validation: {
        email: {
          enabled: boolean;
          confirmationRequired: boolean;
        };
        captcha: {
          enabled: boolean;
        };
      };
    };
    actorId: string;
  };
  maps: {
    tiles: {
      endpoint: string;
      attribution: string | null;
    };
  };
  geocoding: {
    provider: string;
    autocomplete: boolean;
  };
  terms: {
    bodyHtml: string;
    type: InstanceTermsType;
    url: string;
  };
  resourceProviders: IProvider[];
  timezones: string[];
  features: {
    groups: boolean;
  };
}
