import type { IActor, IPerson } from "@/types/actor";
import type { IEvent } from "@/types/event.model";
import type { IComment } from "@/types/comment.model";
import { ActionLogAction, ReportStatusEnum } from "./enums";

export interface IActionLogObject {
  id: string;
}
export interface IReportNote extends IActionLogObject {
  id: string;
  content: string;
  moderator: IActor;
  insertedAt: string;
}
export interface IReport extends IActionLogObject {
  id: string;
  reported: IActor | undefined;
  reporter: IPerson;
  events?: IEvent[];
  comments: IComment[];
  content: string;
  notes: IReportNote[];
  insertedAt: string;
  updatedAt: string;
  status: ReportStatusEnum;
}

export interface IActionLog {
  id: string;
  object: IReport | IReportNote | IEvent | IComment | IActor;
  actor: IActor;
  action: ActionLogAction;
  insertedAt: Date;
}
