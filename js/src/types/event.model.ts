import { IActor } from './actor.model';

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

export interface ICategory {
  title: string;
  description: string;
  picture: string;
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
  category: ICategory;

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
