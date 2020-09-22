import { IGroup, IPerson } from "@/types/actor";
import { IEvent } from "@/types/event.model";

export interface SearchEvent {
  total: number;
  elements: IEvent[];
}

export interface SearchGroup {
  total: number;
  elements: IGroup[];
}

export interface SearchPerson {
  total: number;
  elements: IPerson[];
}

export enum SearchTabs {
  EVENTS = 0,
  GROUPS = 1,
}
