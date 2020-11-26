import { ITag } from "./tag.model";
import { IMedia } from "./media.model";
import { IActor } from "./actor";

export enum PostVisibility {
  PUBLIC = "PUBLIC",
  UNLISTED = "UNLISTED",
  RESTRICTED = "RESTRICTED",
  PRIVATE = "PRIVATE",
}

export interface IPost {
  id?: string;
  slug?: string;
  url?: string;
  local: boolean;
  title: string;
  body: string;
  tags?: ITag[];
  picture?: IMedia | null;
  draft: boolean;
  visibility: PostVisibility;
  author?: IActor;
  attributedTo?: IActor;
  publishAt?: Date;
}
