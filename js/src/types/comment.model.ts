import { IPerson, Person } from "@/types/actor";
import type { IEvent } from "@/types/event.model";
import { EventModel } from "@/types/event.model";
import { IConversation } from "./conversation";

export interface IComment {
  id?: string;
  uuid?: string;
  url?: string;
  text: string;
  local: boolean;
  actor: IPerson | null;
  inReplyToComment?: IComment;
  originComment?: IComment;
  replies: IComment[];
  event?: IEvent;
  updatedAt?: string;
  deletedAt?: string;
  totalReplies: number;
  insertedAt?: string;
  publishedAt?: string;
  isAnnouncement: boolean;
  language?: string;
  conversation?: IConversation;
}

export class CommentModel implements IComment {
  actor: IPerson = new Person();

  id?: string;

  text = "";

  local = true;

  url?: string;

  uuid?: string;

  inReplyToComment?: IComment = undefined;

  originComment?: IComment = undefined;

  replies: IComment[] = [];

  event?: IEvent = undefined;

  updatedAt?: string = undefined;

  deletedAt?: string = undefined;

  insertedAt?: string = undefined;

  totalReplies = 0;

  isAnnouncement = false;

  constructor(hash?: IComment) {
    if (!hash) return;

    this.id = hash.id;
    this.uuid = hash.uuid;
    this.url = hash.url;
    this.text = hash.text;
    this.inReplyToComment = hash.inReplyToComment;
    this.originComment = hash.originComment;
    this.actor = hash.actor ? new Person(hash.actor) : new Person();
    this.event = new EventModel(hash.event);
    this.replies = hash.replies;
    this.updatedAt = new Date(hash.updatedAt as string).toISOString();
    this.deletedAt = hash.deletedAt;
    this.insertedAt = new Date(hash.insertedAt as string).toISOString();
    this.totalReplies = hash.totalReplies;
    this.isAnnouncement = hash.isAnnouncement;
  }
}
