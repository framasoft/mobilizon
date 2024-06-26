import type { Ref } from "vue";

export interface IMedia {
  id: string;
  url: string;
  name: string;
  alt: string;
  metadata: IMediaMetadata;
}

export interface IMediaUpload {
  file: File;
  name: string;
  alt: string | null;
}

export interface IMediaUploadWrapper {
  media: IMediaUpload;
}

export interface IMediaMetadata {
  width?: number;
  height?: number;
  blurhash?: string;
}

export interface IModifiableMedia {
  file: Ref<File | null>;
  firstHash: string | null;
  hash: string | null;
}
