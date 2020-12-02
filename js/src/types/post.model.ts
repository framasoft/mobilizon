import type { ITag } from "./tag.model";
import type { IMedia } from "./media.model";
import type { IActor } from "./actor";
import type { PostVisibility } from "./enums";

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
  insertedAt?: Date;
}
