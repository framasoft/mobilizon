import {Actor, IActor} from './actor.model';

export enum EventStatus {
  TENTATIVE,
  CONFIRMED,
  CANCELLED,
}

export enum EventVisibility {
  PUBLIC,
  UNLISTED,
  RESTRICTED,
  PRIVATE,
}

export enum EventJoinOptions {
  FREE,
  RESTRICTED,
  INVITE,
}

export enum ParticipantRole {
  NOT_APPROVED = 'not_approved',
  PARTICIPANT = 'participant',
  MODERATOR = 'moderator',
  ADMINISTRATOR = 'administrator',
  CREATOR = 'creator',
}

export enum Category {
  BUSINESS = 'business',
  CONFERENCE = 'conference',
  BIRTHDAY = 'birthday',
  DEMONSTRATION = 'demonstration',
  MEETING = 'meeting',
}

export interface IParticipant {
  role: ParticipantRole;
  actor: IActor;
  event: IEvent;
}

export interface IEvent {
  id?: number;
  uuid: string;
  url: string;
  local: boolean;

  title: string;
  description: string;
  category: Category;

  begins_on: Date;
  ends_on: Date;
  publish_at: Date;

  status: EventStatus;
  visibility: EventVisibility;

  join_options: EventJoinOptions;

  thumbnail: string;
  large_image: string;

  organizerActor: IActor;
  attributedTo: IActor;
  participants: IParticipant[];

  // online_address: Address;
  // phone_address: string;
}


export class EventModel implements IEvent {
  begins_on: Date = new Date();
  category: Category = Category.MEETING;
  description: string = '';
  ends_on: Date = new Date();
  join_options: EventJoinOptions = EventJoinOptions.FREE;
  large_image: string = '';
  local: boolean = true;
  participants: IParticipant[] = [];
  publish_at: Date = new Date();
  status: EventStatus = EventStatus.CONFIRMED;
  thumbnail: string = '';
  title: string = '';
  url: string = '';
  uuid: string = '';
  visibility: EventVisibility = EventVisibility.PUBLIC;
  attributedTo: IActor = new Actor();
  organizerActor: IActor = new Actor();
}