import { IActor, IPerson } from "@/types/actor";
import { IEvent } from "@/types/event.model";
import { IComment } from "@/types/comment.model";

export enum ReportStatusEnum {
  OPEN = "OPEN",
  CLOSED = "CLOSED",
  RESOLVED = "RESOLVED",
}

export interface IReport extends IActionLogObject {
  id: string;
  reported: IActor;
  reporter: IPerson;
  event?: IEvent;
  comments: IComment[];
  content: string;
  notes: IReportNote[];
  insertedAt: Date;
  updatedAt: Date;
  status: ReportStatusEnum;
}

export interface IReportNote extends IActionLogObject {
  id: string;
  content: string;
  moderator: IActor;
}

export interface IActionLogObject {
  id: string;
}

export enum ActionLogAction {
  NOTE_CREATION = "NOTE_CREATION",
  NOTE_DELETION = "NOTE_DELETION",
  REPORT_UPDATE_CLOSED = "REPORT_UPDATE_CLOSED",
  REPORT_UPDATE_OPENED = "REPORT_UPDATE_OPENED",
  REPORT_UPDATE_RESOLVED = "REPORT_UPDATE_RESOLVED",
  EVENT_DELETION = "EVENT_DELETION",
  COMMENT_DELETION = "COMMENT_DELETION",
  ACTOR_SUSPENSION = "ACTOR_SUSPENSION",
  ACTOR_UNSUSPENSION = "ACTOR_UNSUSPENSION",
  USER_DELETION = "USER_DELETION",
}

export interface IActionLog {
  id: string;
  object: IReport | IReportNote | IEvent | IComment | IActor;
  actor: IActor;
  action: ActionLogAction;
  insertedAt: Date;
}
