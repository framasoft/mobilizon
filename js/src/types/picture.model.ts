export interface IAbstractPicture {
  name;
  alt;
}

export interface IPicture {
  url;
  name;
  alt;
}

export interface IPictureUpload {
  file: File;
  name: String;
  alt: String|null;
}
