import { IEvent } from "@/types/event.model";

export interface IDashboard {
  lastPublicEventPublished: IEvent;
  numberOfUsers: number;
  numberOfEvents: number;
  numberOfComments: number;
  numberOfReports: number;
}

export enum InstanceTermsType {
  DEFAULT = "DEFAULT",
  URL = "URL",
  CUSTOM = "CUSTOM",
}

export enum InstancePrivacyType {
  DEFAULT = "DEFAULT",
  URL = "URL",
  CUSTOM = "CUSTOM",
}

export interface IAdminSettings {
  instanceName: string;
  instanceDescription: string;
  instanceLongDescription: string;
  contact: string;
  instanceTerms: string;
  instanceTermsType: InstanceTermsType;
  instanceTermsUrl: string | null;
  instancePrivacyPolicy: string;
  instancePrivacyPolicyType: InstanceTermsType;
  instancePrivacyPolicyUrl: string | null;
  instanceRules: string;
  registrationsOpen: boolean;
}
