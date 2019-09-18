import { Actor, IActor } from './actor';
import { IAddress } from '@/types/address.model';
import { ITag } from '@/types/tag.model';
import { IPicture } from '@/types/picture.model';

export enum EventStatus {
  TENTATIVE = 'TENTATIVE',
  CONFIRMED = 'CONFIRMED',
  CANCELLED = 'CANCELLED',
}

export enum EventVisibility {
  PUBLIC = 'PUBLIC',
  UNLISTED = 'UNLISTED',
  RESTRICTED = 'RESTRICTED',
  PRIVATE = 'PRIVATE',
}

export enum EventJoinOptions {
  FREE = 'FREE',
  RESTRICTED = 'RESTRICTED',
  INVITE = 'INVITE',
}

export enum EventVisibilityJoinOptions {
  PUBLIC = 'PUBLIC',
  LINK = 'LINK',
  LIMITED = 'LIMITED',
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

export class Participant implements IParticipant {
  event!: IEvent;
  actor!: IActor;
  role: ParticipantRole = ParticipantRole.NOT_APPROVED;

  constructor(hash?: IParticipant) {
    if (!hash) return;

    this.event = new EventModel(hash.event);
    this.actor = new Actor(hash.actor);
    this.role = hash.role;
  }
}

export interface IOffer {
  price: number;
  priceCurrency: string;
  url: string;
}

export interface IParticipationCondition {
  title: string;
  content: string;
  url: string;
}

export enum CommentModeration {
    ALLOW_ALL = 'ALLOW_ALL',
    MODERATED = 'MODERATED',
    CLOSED = 'CLOSED',
}

export interface IEvent {
  id?: number;
  uuid: string;
  url: string;
  local: boolean;

  title: string;
  slug: string;
  description: string;
  category: Category | null;

  beginsOn: Date;
  endsOn: Date | null;
  publishAt: Date;

  status: EventStatus;
  visibility: EventVisibility;

  joinOptions: EventJoinOptions;

  picture: IPicture | null;

  organizerActor?: IActor;
  attributedTo: IActor;
  participantStats: {
    approved: number;
    unapproved: number;
  };
  participants: IParticipant[];

  relatedEvents: IEvent[];

  onlineAddress?: string;
  phoneAddress?: string;
  physicalAddress?: IAddress;

  tags: ITag[];
  options: IEventOptions;
}

export interface IEventOptions {
  maximumAttendeeCapacity: number;
  remainingAttendeeCapacity: number;
  showRemainingAttendeeCapacity: boolean;
  offers: IOffer[];
  participationConditions: IParticipationCondition[];
  attendees: string[];
  program: string;
  commentModeration: CommentModeration;
  showParticipationPrice: boolean;
}

export class EventOptions implements IEventOptions {
  maximumAttendeeCapacity = 0;
  remainingAttendeeCapacity = 0;
  showRemainingAttendeeCapacity = false;
  offers: IOffer[] = [];
  participationConditions: IParticipationCondition[] = [];
  attendees: string[] = [];
  program = '';
  commentModeration = CommentModeration.ALLOW_ALL;
  showParticipationPrice = false;
}

export class EventModel implements IEvent {
  id?: number;

  beginsOn = new Date();
  endsOn: Date | null = new Date();

  title = '';
  url = '';
  uuid = '';
  slug = '';
  description = '';
  local = true;

  onlineAddress: string | undefined = '';
  phoneAddress: string | undefined = '';
  physicalAddress?: IAddress;

  picture: IPicture | null = null;

  visibility = EventVisibility.PUBLIC;
  category: Category | null = Category.MEETING;
  joinOptions = EventJoinOptions.FREE;
  status = EventStatus.CONFIRMED;

  publishAt = new Date();

  participantStats = { approved: 0, unapproved: 0 };
  participants: IParticipant[] = [];

  relatedEvents: IEvent[] = [];

  attributedTo = new Actor();
  organizerActor?: IActor;

  tags: ITag[] = [];
  options: IEventOptions = new EventOptions();

  constructor(hash?: IEvent) {
    if (!hash) return;

    this.id = hash.id;
    this.uuid = hash.uuid;
    this.url = hash.url;
    this.local = hash.local;

    this.title = hash.title;
    this.slug = hash.slug;
    this.description = hash.description;
    this.category = hash.category;

    this.beginsOn = new Date(hash.beginsOn);
    if (hash.endsOn) this.endsOn = new Date(hash.endsOn);

    this.publishAt = new Date(hash.publishAt);

    this.status = hash.status;
    this.visibility = hash.visibility;

    this.joinOptions = hash.joinOptions;

    this.picture = hash.picture;

    this.organizerActor = new Actor(hash.organizerActor);
    this.attributedTo = new Actor(hash.attributedTo);
    this.participants = hash.participants;

    this.relatedEvents = hash.relatedEvents;

    this.onlineAddress = hash.onlineAddress;
    this.phoneAddress = hash.phoneAddress;
    this.physicalAddress = hash.physicalAddress;
    this.participantStats = hash.participantStats;

    this.tags = hash.tags;
    if (hash.options) this.options = hash.options;
  }

  toEditJSON () {
    return {
      id: this.id,
      title: this.title,
      description: this.description,
      beginsOn: this.beginsOn.toISOString(),
      endsOn: this.endsOn ? this.endsOn.toISOString() : null,
      status: this.status,
      visibility: this.visibility,
      tags: this.tags.map(t => t.title),
      picture: this.picture,
      onlineAddress: this.onlineAddress,
      phoneAddress: this.phoneAddress,
      category: this.category,
      physicalAddress: this.physicalAddress,
      options: this.options,
    };
  }
}
