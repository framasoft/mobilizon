import { IEvent } from '@/types/event.model';

export interface IDashboard {
  lastPublicEventPublished: IEvent;
  numberOfUsers: number;
  numberOfEvents: number;
  numberOfComments: number;
  numberOfReports: number;
}
