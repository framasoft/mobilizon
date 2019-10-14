export interface IPicture {
  id: string;
  url: string;
  name: string;
  alt: string;
}

export interface IPictureUpload {
  file: File;
  name: string;
  alt: string | null;
}
