import { Actor, IActor } from './actor.model';
import { IAddress } from '@/types/address.model';

export enum EventStatus {
  TENTATIVE,
  CONFIRMED,
  CANCELLED,
}

export enum EventVisibility {
  PUBLIC = 'PUBLIC',
  UNLISTED = 'UNLISTED',
  RESTRICTED = 'RESTRICTED',
  PRIVATE = 'PRIVATE',
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

  beginsOn: Date;
  endsOn: Date;
  publishAt: Date;

  status: EventStatus;
  visibility: EventVisibility;

  joinOptions: EventJoinOptions;

  thumbnail: string;
  largeImage: string;

  organizerActor: IActor;
  attributedTo: IActor;
  participants: IParticipant[];

  onlineAddress?: string;
  phoneAddress?: string;
  physicalAddress?: IAddress;
}


export class EventModel implements IEvent {
  beginsOn: Date = new Date();
  category: Category = Category.MEETING;
  description: string = '';
  endsOn: Date = new Date();
  joinOptions: EventJoinOptions = EventJoinOptions.FREE;
  largeImage: string = '';
  local: boolean = true;
  participants: IParticipant[] = [];
  publishAt: Date = new Date();
  status: EventStatus = EventStatus.CONFIRMED;
  thumbnail: string = '';
  title: string = '';
  url: string = '';
  uuid: string = '';
  visibility: EventVisibility = EventVisibility.PUBLIC;
  attributedTo: IActor = new Actor();
  organizerActor: IActor = new Actor();
  onlineAddress: string = '';
  phoneAddress: string = '';
}
