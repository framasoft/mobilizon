import { Address } from "@/types/address.model";
import type { IAddress } from "@/types/address.model";
import type { ITag } from "@/types/tag.model";
import type { IMedia } from "@/types/media.model";
import type { IComment } from "@/types/comment.model";
import type { Paginate } from "@/types/paginate";
import { Actor, Group } from "./actor";
import type { IActor, IGroup, IPerson } from "./actor";
import type { IParticipant } from "./participant.model";
import { EventOptions } from "./event-options.model";
import type { IEventOptions } from "./event-options.model";
import { EventJoinOptions, EventStatus, EventVisibility } from "./enums";

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
  beginsOn: string;
  endsOn: string | null;
  status: EventStatus;
  visibility: EventVisibility;
  joinOptions: EventJoinOptions;
  draft: boolean;
  picture?: IMedia | { mediaId: string } | null;
  attributedToId: string | null;
  onlineAddress?: string;
  phoneAddress?: string;
  physicalAddress?: IAddress;
  tags: string[];
  options: IEventOptions;
  contacts: { id?: string }[];
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
  physicalAddress?: IAddress;

  tags: ITag[];
  options: IEventOptions;
  contacts: IActor[];

  toEditJSON(): IEventEditJSON;
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

  physicalAddress?: IAddress;

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

  constructor(hash?: IEvent) {
    if (!hash) return;

    this.id = hash.id;
    this.uuid = hash.uuid;
    this.url = hash.url;
    this.local = hash.local;

    this.title = hash.title;
    this.slug = hash.slug;
    this.description = hash.description || "";

    this.beginsOn = new Date(hash.beginsOn);
    if (hash.endsOn) this.endsOn = new Date(hash.endsOn);

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
      : undefined;
    this.participantStats = hash.participantStats;

    this.contacts = hash.contacts;

    this.tags = hash.tags;
    if (hash.options) this.options = hash.options;
  }

  toEditJSON(): IEventEditJSON {
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
      tags: this.tags.map((t) => t.title),
      onlineAddress: this.onlineAddress,
      phoneAddress: this.phoneAddress,
      physicalAddress: this.physicalAddress,
      options: this.options,
      attributedToId:
        this.attributedTo && this.attributedTo.id ? this.attributedTo.id : null,
      contacts: this.contacts.map(({ id }) => ({
        id,
      })),
    };
  }
}
