import type { IGroup, IPerson } from "@/types/actor";
import type { IEvent } from "@/types/event.model";

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
