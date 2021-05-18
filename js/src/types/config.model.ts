import { InstancePrivacyType, InstanceTermsType, RoutingType } from "./enums";
import type { IProvider } from "./resource";

export interface IOAuthProvider {
  id: string;
  label: string;
}

export interface IConfig {
  name: string;
  description: string;
  longDescription: string;
  contact: string;
  slogan: string;

  registrationsOpen: boolean;
  registrationsAllowlist: boolean;
  demoMode: boolean;
  countryCode: string;
  languages: string[];
  location: {
    latitude: number;
    longitude: number;
    // accuracyRadius: number;
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
    reports: {
      allowed: boolean;
    };
    actorId: string;
  };
  maps: {
    tiles: {
      endpoint: string;
      attribution: string | null;
    };
    routing: {
      type: RoutingType;
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
  privacy: {
    bodyHtml: string;
    type: InstancePrivacyType;
    url: string;
  };
  rules: string;
  resourceProviders: IProvider[];
  timezones: string[];
  features: {
    eventCreation: boolean;
    groups: boolean;
    koenaConnect: boolean;
  };
  federating: boolean;
  version: string;
  auth: {
    ldap: boolean;
    oauthProviders: IOAuthProvider[];
  };
  uploadLimits: {
    default: number;
    avatar: number;
    banner: number;
  };
  instanceFeeds: {
    enabled: boolean;
  };
}
