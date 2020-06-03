import { Paginate } from "@/types/paginate";
import { IActor } from "@/types/actor";

export interface IResource {
  id?: string;
  title: string;
  summary?: string;
  actor?: IActor;
  url?: string;
  resourceUrl: string;
  path?: string;
  children: Paginate<IResource>;
  parent?: IResource;
  metadata: IResourceMetadata;
  insertedAt?: Date;
  updatedAt?: Date;
  creator?: IActor;
  type?: string;
}

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

export const mapServiceTypeToIcon: object = {
  pad: "file-document-outline",
  calc: "google-spreadsheet",
  visio: "webcam",
};

export interface IProvider {
  type: string;
  endpoint: string;
  software: string;
}
