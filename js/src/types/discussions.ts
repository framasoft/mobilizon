import type { IActor, IPerson } from "@/types/actor";
import type { IComment } from "@/types/comment.model";
import { CommentModel } from "@/types/comment.model";
import type { Paginate } from "@/types/paginate";

export interface IDiscussion {
  id?: string;
  title: string;
  slug?: string;
  creator?: IPerson;
  actor?: IActor;
  lastComment?: IComment;
  comments: Paginate<IComment>;
  updatedAt: string;
  insertedAt: string;
}

export class Discussion implements IDiscussion {
  id?: string;

  title = "";

  comments: Paginate<IComment> = { total: 0, elements: [] };

  slug?: string = undefined;

  creator?: IPerson = undefined;

  actor?: IActor = undefined;

  lastComment?: IComment = undefined;

  insertedAt = "";

  updatedAt = "";

  constructor(hash?: IDiscussion) {
    if (!hash) return;

    this.id = hash.id;
    this.title = hash.title;
    this.comments = {
      total: hash.comments.total,
      elements: hash.comments.elements.map(
        (comment: IComment) => new CommentModel(comment)
      ),
    };
    this.slug = hash.slug;
    this.creator = hash.creator;
    this.actor = hash.actor;
    this.lastComment = hash.lastComment;
    this.insertedAt = hash.insertedAt;
    this.updatedAt = hash.updatedAt;
  }
}
