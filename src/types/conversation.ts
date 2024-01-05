import type { IActor } from "@/types/actor";
import type { IComment } from "@/types/comment.model";
import type { Paginate } from "@/types/paginate";
import { IEvent } from "./event.model";

export interface IConversation {
  conversationParticipantId?: string;
  id?: string;
  actor?: IActor;
  lastComment?: IComment;
  originComment?: IComment;
  comments: Paginate<IComment>;
  participants: IActor[];
  updatedAt: string;
  insertedAt: string;
  unread: boolean;
  event?: IEvent;
}
