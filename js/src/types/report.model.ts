import { IActor, IPerson } from '@/types/actor';
import { IEvent } from '@/types/event.model';

export enum ReportStatusEnum {
    OPEN = 'OPEN',
    CLOSED = 'CLOSED',
    RESOLVED = 'RESOLVED',
}

export interface IReport extends IActionLogObject {
  id: string;
  reported: IActor;
  reporter: IPerson;
  event?: IEvent;
  content: string;
  notes: IReportNote[];
  insertedAt: Date;
  updatedAt: Date;
  status: ReportStatusEnum;
}

export interface IReportNote extends IActionLogObject{
  id: string;
  content: string;
  moderator: IActor;
}

export interface IActionLogObject {
  id: string;
}

export enum ActionLogAction {
    NOTE_CREATION = 'NOTE_CREATION',
    NOTE_DELETION = 'NOTE_DELETION',
    REPORT_UPDATE_CLOSED = 'REPORT_UPDATE_CLOSED',
    REPORT_UPDATE_OPENED = 'REPORT_UPDATE_OPENED',
    REPORT_UPDATE_RESOLVED = 'REPORT_UPDATE_RESOLVED',
    EVENT_DELETION = 'EVENT_DELETION',
}

export interface IActionLog {
  id: string;
  object: IReport|IReportNote|IEvent;
  actor: IActor;
  action: ActionLogAction;
  insertedAt: Date;
}
