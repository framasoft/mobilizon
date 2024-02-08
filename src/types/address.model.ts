import { poiIcons } from "@/utils/poiIcons";
import type { IPOIIcon } from "@/utils/poiIcons";
import { PictureInformation } from "./picture";

export interface IAddress {
  id?: string;
  description: string;
  street: string;
  locality: string;
  postalCode: string;
  region: string;
  country: string;
  type: string;
  geom?: string;
  url?: string;
  originId?: string;
  timezone?: string;
  pictureInfo?: PictureInformation;
  poiInfos?: IPoiInfo;
}

export interface IPoiInfo {
  name: string;
  alternativeName: string;
  poiIcon: IPOIIcon;
}

export class Address implements IAddress {
  country = "";

  description = "";

  locality = "";

  postalCode = "";

  region = "";

  street = "";

  type = "";

  id?: string = "";

  originId?: string = "";

  url?: string = "";

  geom?: string = "";

  timezone?: string = "";

  constructor(hash?: IAddress) {
    if (!hash) return;

    this.id = hash.id;
    this.description = hash.description?.trim();
    this.street = hash.street?.trim();
    this.locality = hash.locality?.trim();
    this.postalCode = hash.postalCode?.trim();
    this.region = hash.region?.trim();
    this.country = hash.country?.trim();
    this.type = hash.type;
    this.geom = hash.geom;
    this.url = hash.url;
    this.originId = hash.originId;
    this.timezone = hash.timezone;
  }

  get poiInfos(): IPoiInfo {
    return addressToPoiInfos(this);
  }

  get fullName(): string {
    return addressFullName(this);
  }

  get iconForPOI(): IPOIIcon {
    return iconForAddress(this);
  }
}

export function addressToPoiInfos(address: IAddress): IPoiInfo {
  /* generate name corresponding to poi type */
  let name = "";
  let alternativeName = "";
  let poiIcon: IPOIIcon = poiIcons.default;
  let addressType = address.type;
  // Google Maps doesn't have a type
  if (address.type == null && address.description === address.street) {
    addressType = "house";
  }
  switch (addressType) {
    case "house":
      name = address.description;
      alternativeName = (
        address.description !== address.street ? [address.street] : []
      )
        .concat([address.postalCode, address.locality, address.country])
        .filter((zone) => zone)
        .join(", ");
      poiIcon = poiIcons.defaultAddress;
      break;
    case "street":
    case "secondary":
      name = address.description;
      alternativeName = [address.postalCode, address.locality, address.country]
        .filter((zone) => zone)
        .join(", ");
      poiIcon = poiIcons.defaultStreet;
      break;
    case "zone":
    case "city":
    case "administrative":
      name = address.postalCode
        ? `${address.description} (${address.postalCode})`
        : address.description;
      alternativeName = [address.region, address.country]
        .filter((zone) => zone)
        .join(", ");
      poiIcon = poiIcons.defaultAdministrative;
      break;
    default:
      // POI
      name = address.description;
      alternativeName = "";
      if (address.street && address.street.trim()) {
        alternativeName = `${address.street}`;
        if (address.postalCode) {
          alternativeName += `, ${address.postalCode}`;
        }
        if (address.locality) {
          alternativeName += `, ${address.locality}`;
        }
      } else if (address.locality && address.locality.trim()) {
        alternativeName = `${address.locality}, ${address.region}, ${address.country}`;
      } else if (address.region && address.region.trim()) {
        alternativeName = `${address.region}, ${address.country}`;
      } else if (address.country && address.country.trim()) {
        alternativeName = address.country;
      }
      poiIcon = iconForAddress(address);
      break;
  }
  return { name, alternativeName, poiIcon };
}

export function iconForAddress(address: IAddress): IPOIIcon {
  if (address.type == null) {
    return poiIcons.default;
  }
  const type = address.type.split(":").pop() || "";
  if (poiIcons[type]) return poiIcons[type];
  return poiIcons.default;
}

export function addressFullName(address: IAddress): string {
  if (!address) return "";
  const { name, alternativeName } = addressToPoiInfos(address);
  if (name && alternativeName) {
    return `${name}, ${alternativeName}`;
  }
  if (name) {
    return name;
  }
  return "";
}

export function resetAddress(address: IAddress): void {
  address.id = undefined;
  address.description = "";
  address.street = "";
  address.locality = "";
  address.postalCode = "";
  address.region = "";
  address.country = "";
  address.type = "";
  address.geom = undefined;
  address.url = undefined;
  address.originId = undefined;
  address.timezone = undefined;
  address.pictureInfo = undefined;
}
