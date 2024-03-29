import type { Paginate } from "@/types/paginate";
import type { IActor, IGroup } from "@/types/actor";

export interface IResourceMetadata {
  title?: string;
  description?: string;
  imageRemoteUrl?: string;
  height?: number;
  width?: number;
  type?: string;
  authorName?: string;
  authorUrl?: string;
  providerName?: string;
  providerUrl?: string;
  html?: string;
  faviconUrl?: string;
}
export interface IResource {
  id?: string;
  title: string;
  summary?: string;
  actor?: IGroup;
  url?: string;
  resourceUrl: string;
  path?: string;
  children: Paginate<IResource>;
  parent?: IResource;
  metadata: IResourceMetadata;
  insertedAt?: string;
  updatedAt?: string;
  publishedAt?: string;
  creator?: IActor;
  type?: string;
}

export const mapServiceTypeToIcon: Record<string, string> = {
  pad: "file-document-outline",
  calc: "google-spreadsheet",
  visio: "webcam",
};

export interface IProvider {
  type: string;
  endpoint: string;
  software: string;
}
