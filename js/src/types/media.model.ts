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

export interface IMediaMetadata {
  width?: number;
  height?: number;
  blurhash?: string;
}
