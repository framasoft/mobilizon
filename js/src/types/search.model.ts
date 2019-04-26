import { IGroup } from '@/types/actor';
import { IEvent } from '@/types/event.model';

export interface SearchEvent {
  total: number;
  elements: IEvent[];
}

export interface SearchGroup {
  total: number;
  elements: IGroup[];
}
