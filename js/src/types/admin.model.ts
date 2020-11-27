import type { IEvent } from "@/types/event.model";
import type { IGroup } from "./actor";
import { InstanceTermsType } from "./enums";

export interface IDashboard {
  lastPublicEventPublished: IEvent;
  lastGroupCreated: IGroup;
  numberOfUsers: number;
  numberOfEvents: number;
  numberOfComments: number;
  numberOfReports: number;
  numberOfGroups: number;
  numberOfFollowers: number;
  numberOfFollowings: number;
  numberOfConfirmedParticipationsToLocalEvents: number;
}

export interface ILanguage {
  code: string;
  name: string;
}
export interface IAdminSettings {
  instanceName: string;
  instanceDescription: string;
  instanceSlogan: string;
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
  instanceLanguages: string[];
}
