import { IEvent } from '@/types/event.model';

export interface IDashboard {
  lastPublicEventPublished: IEvent;
  numberOfUsers: number;
  numberOfEvents: number;
  numberOfComments: number;
  numberOfReports: number;
}

export enum InstanceTermsType {
  DEFAULT = 'DEFAULT',
  URL = 'URL',
  CUSTOM = 'CUSTOM',
}

export interface IAdminSettings {
  instanceName: string;
  instanceDescription: string;
  instanceTerms: string;
  instanceTermsType: InstanceTermsType;
  instanceTermsUrl: string|null;
  registrationsOpen: boolean;
}
