import { PictureInformation } from "./picture";

export type LocationType = {
  lat: number | undefined;
  lon: number | undefined;
  name: string | undefined;
  picture?: PictureInformation;
  isIPLocation?: boolean;
  accuracy?: number;
};
