import { Actor } from "@/types/actor";
import type { IActor } from "@/types/actor";
import type { IEvent } from "@/types/event.model";
import { EventModel } from "@/types/event.model";

export interface IComment {
  id?: string;
  uuid?: string;
  url?: string;
  text: string;
  local: boolean;
  actor: IActor | null;
  inReplyToComment?: IComment;
  originComment?: IComment;
  replies: IComment[];
  event?: IEvent;
  updatedAt?: Date | string;
  deletedAt?: Date | string;
  totalReplies: number;
  insertedAt?: Date | string;
  publishedAt?: Date | string;
}

export class CommentModel implements IComment {
  actor: IActor = new Actor();

  id?: string;

  text = "";

  local = true;

  url?: string;

  uuid?: string;

  inReplyToComment?: IComment = undefined;

  originComment?: IComment = undefined;

  replies: IComment[] = [];

  event?: IEvent = undefined;

  updatedAt?: Date | string = undefined;

  deletedAt?: Date | string = undefined;

  insertedAt?: Date | string = undefined;

  totalReplies = 0;

  constructor(hash?: IComment) {
    if (!hash) return;

    this.id = hash.id;
    this.uuid = hash.uuid;
    this.url = hash.url;
    this.text = hash.text;
    this.inReplyToComment = hash.inReplyToComment;
    this.originComment = hash.originComment;
    this.actor = hash.actor ? new Actor(hash.actor) : new Actor();
    this.event = new EventModel(hash.event);
    this.replies = hash.replies;
    this.updatedAt = new Date(hash.updatedAt as string);
    this.deletedAt = hash.deletedAt;
    this.insertedAt = new Date(hash.insertedAt as string);
    this.totalReplies = hash.totalReplies;
  }
}
