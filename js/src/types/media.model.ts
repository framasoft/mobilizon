export interface IMedia {
  id: string;
  url: string;
  name: string;
  alt: string;
}

export interface IMediaUpload {
  file: File;
  name: string;
  alt: string | null;
}
