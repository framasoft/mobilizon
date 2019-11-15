import { Actor, IActor } from '@/types/actor';
import { EventModel, IEvent } from '@/types/event.model';

export interface IComment {
  id?: string;
  uuid?: string;
  url?: string;
  text: string;
  actor: IActor;
  inReplyToComment?: IComment;
  originComment?: IComment;
  replies: IComment[];
  event?: IEvent;
  updatedAt?: Date;
  deletedAt?: Date;
  totalReplies: number;
}

export class CommentModel implements IComment {
  actor: IActor = new Actor();
  id?: string;
  text: string = '';
  url?: string;
  uuid?: string;
  inReplyToComment?: IComment = undefined;
  originComment?: IComment = undefined;
  replies: IComment[] = [];
  event?: IEvent = undefined;
  updatedAt?: Date = undefined;
  deletedAt?: Date = undefined;
  totalReplies: number = 0;

  constructor(hash?: IComment) {
    if (!hash) return;

    this.id = hash.id;
    this.uuid = hash.uuid;
    this.url = hash.url;
    this.text = hash.text;
    this.inReplyToComment = hash.inReplyToComment;
    this.originComment = hash.originComment;
    this.actor = new Actor(hash.actor);
    this.event = new EventModel(hash.event);
    this.replies = hash.replies;
    this.updatedAt = hash.updatedAt;
    this.deletedAt = hash.deletedAt;
    this.totalReplies = hash.totalReplies;
  }

}
