import { Actor, IActor } from './actor';
import { IAddress } from '@/types/address.model';
import { ITag } from '@/types/tag.model';
import { IAbstractPicture, IPicture } from '@/types/picture.model';

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
  slug: string;
  description: string;
  category: Category;

  beginsOn: Date;
  endsOn: Date;
  publishAt: Date;

  status: EventStatus;
  visibility: EventVisibility;

  joinOptions: EventJoinOptions;

  picture: IAbstractPicture|null;

  organizerActor: IActor;
  attributedTo: IActor;
  participants: IParticipant[];

  relatedEvents: IEvent[];

  onlineAddress?: string;
  phoneAddress?: string;
  physicalAddress?: IAddress;
}


export class EventModel implements IEvent {
  beginsOn: Date = new Date();
  category: Category = Category.MEETING;
  slug: string = '';
  description: string = '';
  endsOn: Date = new Date();
  joinOptions: EventJoinOptions = EventJoinOptions.FREE;
  local: boolean = true;
  participants: IParticipant[] = [];
  publishAt: Date = new Date();
  status: EventStatus = EventStatus.CONFIRMED;
  title: string = '';
  url: string = '';
  uuid: string = '';
  visibility: EventVisibility = EventVisibility.PUBLIC;
  attributedTo: IActor = new Actor();
  organizerActor: IActor = new Actor();
  relatedEvents: IEvent[] = [];
  onlineAddress: string = '';
  phoneAddress: string = '';
  picture: IAbstractPicture|null = null;
}
