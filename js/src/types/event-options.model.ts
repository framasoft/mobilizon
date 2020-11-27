import { CommentModeration } from "./enums";

export interface IParticipationCondition {
  title: string;
  content: string;
  url: string;
}

export interface IOffer {
  price: number;
  priceCurrency: string;
  url: string;
}

export interface IEventOptions {
  maximumAttendeeCapacity: number;
  remainingAttendeeCapacity: number;
  showRemainingAttendeeCapacity: boolean;
  anonymousParticipation: boolean;
  hideOrganizerWhenGroupEvent: boolean;
  offers: IOffer[];
  participationConditions: IParticipationCondition[];
  attendees: string[];
  program: string;
  commentModeration: CommentModeration;
  showParticipationPrice: boolean;
  showStartTime: boolean;
  showEndTime: boolean;
}

export class EventOptions implements IEventOptions {
  maximumAttendeeCapacity = 0;

  remainingAttendeeCapacity = 0;

  showRemainingAttendeeCapacity = false;

  anonymousParticipation = false;

  hideOrganizerWhenGroupEvent = false;

  offers: IOffer[] = [];

  participationConditions: IParticipationCondition[] = [];

  attendees: string[] = [];

  program = "";

  commentModeration = CommentModeration.ALLOW_ALL;

  showParticipationPrice = false;

  showStartTime = true;

  showEndTime = true;
}
