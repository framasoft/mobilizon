import { Address } from "@/types/address.model";
import type { IAddress } from "@/types/address.model";
import type { ITag } from "@/types/tag.model";
import type { IMedia } from "@/types/media.model";
import type { IComment } from "@/types/comment.model";
import type { Paginate } from "@/types/paginate";
import { Actor, displayName, Group } from "./actor";
import type { IActor, IGroup, IPerson } from "./actor";
import type { IParticipant } from "./participant.model";
import { EventOptions } from "./event-options.model";
import type { IEventOptions } from "./event-options.model";
import { EventJoinOptions, EventStatus, EventVisibility } from "./enums";
import { IEventMetadata } from "./event-metadata";

export interface IEventCardOptions {
  hideDate: boolean;
  loggedPerson: IPerson | boolean;
  hideDetails: boolean;
  organizerActor: IActor | null;
  memberofGroup: boolean;
}

export interface IEventParticipantStats {
  notApproved: number;
  notConfirmed: number;
  rejected: number;
  participant: number;
  creator: number;
  moderator: number;
  administrator: number;
  going: number;
}

interface IEventEditJSON {
  id?: string;
  title: string;
  description: string;
  beginsOn: string | null;
  endsOn: string | null;
  status: EventStatus;
  visibility: EventVisibility;
  joinOptions: EventJoinOptions;
  draft: boolean;
  picture?: IMedia | { mediaId: string } | null;
  attributedToId: string | null;
  organizerActorId?: string;
  onlineAddress?: string;
  phoneAddress?: string;
  physicalAddress?: IAddress;
  tags: string[];
  options: IEventOptions;
  contacts: { id?: string }[];
  metadata: IEventMetadata[];
}

export interface IEvent {
  id?: string;
  uuid: string;
  url: string;
  local: boolean;

  title: string;
  slug: string;
  description: string;
  beginsOn: Date;
  endsOn: Date | null;
  publishAt: Date;
  status: EventStatus;
  visibility: EventVisibility;
  joinOptions: EventJoinOptions;
  draft: boolean;

  picture: IMedia | null;

  organizerActor?: IActor;
  attributedTo?: IGroup;
  participantStats: IEventParticipantStats;
  participants: Paginate<IParticipant>;

  relatedEvents: IEvent[];
  comments: IComment[];

  onlineAddress?: string;
  phoneAddress?: string;
  physicalAddress: IAddress | null;

  tags: ITag[];
  options: IEventOptions;
  metadata: IEventMetadata[];
  contacts: IActor[];

  toEditJSON(): IEventEditJSON;
}

export interface IEditableEvent extends Omit<IEvent, "beginsOn"> {
  beginsOn: Date | null;
}
export class EventModel implements IEvent {
  id?: string;

  beginsOn = new Date();

  endsOn: Date | null = new Date();

  title = "";

  url = "";

  uuid = "";

  slug = "";

  description = "";

  local = true;

  onlineAddress: string | undefined = "";

  phoneAddress: string | undefined = "";

  physicalAddress: IAddress | null = null;

  picture: IMedia | null = null;

  visibility = EventVisibility.PUBLIC;

  joinOptions = EventJoinOptions.FREE;

  status = EventStatus.CONFIRMED;

  draft = true;

  publishAt = new Date();

  participantStats = {
    notApproved: 0,
    notConfirmed: 0,
    rejected: 0,
    participant: 0,
    moderator: 0,
    administrator: 0,
    creator: 0,
    going: 0,
  };

  participants!: Paginate<IParticipant>;

  relatedEvents: IEvent[] = [];

  comments: IComment[] = [];

  attributedTo?: IGroup = new Group();

  organizerActor?: IActor = new Actor();

  tags: ITag[] = [];

  contacts: IActor[] = [];

  options: IEventOptions = new EventOptions();

  metadata: IEventMetadata[] = [];

  constructor(hash?: IEvent | IEditableEvent) {
    if (!hash) return;

    this.id = hash.id;
    this.uuid = hash.uuid;
    this.url = hash.url;
    this.local = hash.local;

    this.title = hash.title;
    this.slug = hash.slug;
    this.description = hash.description || "";

    if (hash.beginsOn) {
      this.beginsOn = new Date(hash.beginsOn);
    }
    if (hash.endsOn) {
      this.endsOn = new Date(hash.endsOn);
    } else {
      this.endsOn = null;
    }

    this.publishAt = new Date(hash.publishAt);

    this.status = hash.status;
    this.visibility = hash.visibility;
    this.joinOptions = hash.joinOptions;
    this.draft = hash.draft;

    this.picture = hash.picture;

    this.organizerActor = new Actor(hash.organizerActor);
    this.attributedTo = new Group(hash.attributedTo);
    this.participants = hash.participants;

    this.relatedEvents = hash.relatedEvents;

    this.onlineAddress = hash.onlineAddress;
    this.phoneAddress = hash.phoneAddress;
    this.physicalAddress = hash.physicalAddress
      ? new Address(hash.physicalAddress)
      : null;
    this.participantStats = hash.participantStats;

    this.contacts = hash.contacts;

    this.tags = hash.tags;
    this.metadata = hash.metadata;
    if (hash.options) this.options = hash.options;
  }

  toEditJSON(): IEventEditJSON {
    return toEditJSON(this);
  }
}

// eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
export function removeTypeName(entity: any): any {
  if (entity?.__typename) {
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { __typename, ...purgedEntity } = entity;
    return purgedEntity;
  }
  return entity;
}

export function toEditJSON(event: IEditableEvent): IEventEditJSON {
  return {
    id: event.id,
    title: event.title,
    description: event.description,
    beginsOn: event.beginsOn ? event.beginsOn.toISOString() : null,
    endsOn: event.endsOn ? event.endsOn.toISOString() : null,
    status: event.status,
    visibility: event.visibility,
    joinOptions: event.joinOptions,
    draft: event.draft,
    tags: event.tags.map((t) => t.title),
    onlineAddress: event.onlineAddress,
    phoneAddress: event.phoneAddress,
    physicalAddress: removeTypeName(event.physicalAddress),
    options: removeTypeName(event.options),
    metadata: event.metadata.map(({ key, value, type, title }) => ({
      key,
      value,
      type,
      title,
    })),
    attributedToId:
      event.attributedTo && event.attributedTo.id
        ? event.attributedTo.id
        : null,
    contacts: event.contacts.map(({ id }) => ({
      id,
    })),
  };
}

export function organizer(event: IEvent): IActor | null {
  if (event.attributedTo) {
    return event.attributedTo;
  }
  if (event.organizerActor) {
    return event.organizerActor;
  }
  return null;
}

export function organizerDisplayName(event: IEvent): string | null {
  const organizerActor = organizer(event);
  if (organizerActor) {
    return displayName(organizerActor);
  }
  return null;
}
