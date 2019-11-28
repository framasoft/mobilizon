import { Actor, IActor, IPerson } from './actor';
import { Address, IAddress } from '@/types/address.model';
import { ITag } from '@/types/tag.model';
import { IPicture } from '@/types/picture.model';
import { IComment } from '@/types/comment.model';

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
  NOT_APPROVED = 'NOT_APPROVED',
  REJECTED = 'REJECTED',
  PARTICIPANT = 'PARTICIPANT',
  MODERATOR = 'MODERATOR',
  ADMINISTRATOR = 'ADMINISTRATOR',
  CREATOR = 'CREATOR',
}

export enum Category {
  BUSINESS = 'business',
  CONFERENCE = 'conference',
  BIRTHDAY = 'birthday',
  DEMONSTRATION = 'demonstration',
  MEETING = 'meeting',
}

export interface IEventCardOptions {
  hideDate: boolean;
  loggedPerson: IPerson | boolean;
  hideDetails: boolean;
  organizerActor: IActor | null;
}

export interface IParticipant {
  id?: string;
  role: ParticipantRole;
  actor: IActor;
  event: IEvent;
}

export class Participant implements IParticipant {
  id?: string;
  event!: IEvent;
  actor!: IActor;
  role: ParticipantRole = ParticipantRole.NOT_APPROVED;

  constructor(hash?: IParticipant) {
    if (!hash) return;

    this.id = hash.id;
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

export interface IEventParticipantStats {
  notApproved: number;
  rejected: number;
  participant: number;
  creator: number;
  moderator: number;
  administrator: number;
  going: number;
}

export interface IEvent {
  id?: string;
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
  draft: boolean;

  picture: IPicture | null;

  organizerActor?: IActor;
  attributedTo: IActor;
  participantStats: IEventParticipantStats;
  participants: IParticipant[];

  relatedEvents: IEvent[];
  comments: IComment[];

  onlineAddress?: string;
  phoneAddress?: string;
  physicalAddress?: IAddress;

  tags: ITag[];
  options: IEventOptions;

  toEditJSON();
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
  showStartTime: boolean;
  showEndTime: boolean;
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
  showStartTime = true;
  showEndTime = true;
}

export class EventModel implements IEvent {
  id?: string;

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
  draft = true;

  publishAt = new Date();

  participantStats = { notApproved: 0, rejected: 0, participant: 0, moderator: 0, administrator: 0, creator: 0, going: 0 };
  participants: IParticipant[] = [];

  relatedEvents: IEvent[] = [];
  comments: IComment[] = [];

  attributedTo = new Actor();
  organizerActor?: IActor = new Actor();

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
    this.draft = hash.draft;

    this.picture = hash.picture;

    this.organizerActor = new Actor(hash.organizerActor);
    this.attributedTo = new Actor(hash.attributedTo);
    this.participants = hash.participants;

    this.relatedEvents = hash.relatedEvents;

    this.onlineAddress = hash.onlineAddress;
    this.phoneAddress = hash.phoneAddress;
    this.physicalAddress = new Address(hash.physicalAddress);
    this.participantStats = hash.participantStats;

    this.tags = hash.tags;
    if (hash.options) this.options = hash.options;
  }

  toEditJSON() {
    return {
      id: this.id,
      title: this.title,
      description: this.description,
      beginsOn: this.beginsOn.toISOString(),
      endsOn: this.endsOn ? this.endsOn.toISOString() : null,
      status: this.status,
      visibility: this.visibility,
      joinOptions: this.joinOptions,
      draft: this.draft,
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
