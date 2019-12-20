import { InstanceTermsType } from '@/types/admin.model';

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
        },
        captcha: {
          enabled: boolean;
        },
      }
    }
    eventCreation: {
      allowed: boolean;
      validation: {
        email: {
          enabled: boolean;
          confirmationRequired: boolean;
        },
        captcha: {
          enabled: boolean,
        },
      }
    }
    actorId,
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
  terms: {
    bodyHtml: string;
    type: InstanceTermsType;
    url: string;
  };
}
