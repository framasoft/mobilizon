import { IActor, IPerson } from "@/types/actor";
import { IComment } from "@/types/comment.model";
import { Paginate } from "@/types/paginate";

export interface IConversation {
  id: string;
  title: string;
  slug: string;
  creator: IPerson;
  actor: IActor;
  lastComment: IComment;
  comments: Paginate<IComment>;
}
