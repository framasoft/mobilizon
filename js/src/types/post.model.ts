import { ITag } from "./tag.model";
import { IPicture } from "./picture.model";
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
  picture?: IPicture | null;
  draft: boolean;
  visibility: PostVisibility;
  author?: IActor;
  attributedTo?: IActor;
  publishAt?: Date;
}
