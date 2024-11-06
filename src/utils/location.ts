import ngeohash from "ngeohash";

import { IAddress, Address } from "@/types/address.model";
import { LocationType } from "@/types/user-location.model";
import { IUserPreferredLocation } from "@/types/current-user.model";

const GEOHASH_DEPTH = 9; // put enough accuracy, radius will be used anyway

export const addressToLocation = (
  address: IAddress
): LocationType | undefined => {
  if (!address.geom)
    return {
      lon: undefined,
      lat: undefined,
      name: undefined,
    };
  const arr = address.geom.split(";");
  if (arr.length < 2)
    return {
      lon: undefined,
      lat: undefined,
      name: undefined,
    };
  return {
    lon: parseFloat(arr[0]),
    lat: parseFloat(arr[1]),
    name: address.description,
  };
};

export const locationToAddress = (location: LocationType): IAddress | null => {
  if (location.lon && location.lat) {
    const new_add = new Address();
    new_add.geom = location.lon.toString() + ";" + location.lat.toString();
    new_add.description = location.name || "";
    console.debug("locationToAddress", location, new_add);
    return new_add;
  }
  return null;
};

export const coordsToGeoHash = (
  lat: number | undefined,
  lon: number | undefined,
  depth = GEOHASH_DEPTH
): string | undefined => {
  if (lat && lon && depth) {
    return ngeohash.encode(lat, lon, GEOHASH_DEPTH);
  }
  return undefined;
};

export const geoHashToCoords = (
  geohash: string | undefined | null
): { latitude: number; longitude: number } | undefined => {
  if (!geohash) return undefined;
  const { latitude, longitude } = ngeohash.decode(geohash);
  return latitude && longitude ? { latitude, longitude } : undefined;
};

export const storeAddressInLocal = (address: IAddress | null): undefined => {
  if (address) {
    window.localStorage.setItem("address", JSON.stringify(address));
  } else {
    window.localStorage.removeItem("address");
  }
};

export const getAddressFromLocal = (): IAddress | null => {
  const addressString = window.localStorage.getItem("address");
  if (!addressString) {
    return null;
  }
  const address = JSON.parse(addressString) as IAddress;
  if (!address.description || !address.geom) {
    return null;
  }
  return address;
};

export const storeUserLocationAndRadiusFromUserSettings = (
  location: IUserPreferredLocation | null
): undefined => {
  if (location) {
    const latlon = geoHashToCoords(location.geohash);
    if (latlon) {
      storeAddressInLocal({
        ...new Address(),
        geom: `${latlon.longitude};${latlon.latitude}`,
        description: location.name || "",
        type: "administrative",
      });
    }
  } else {
    console.debug("user has not set a location");
  }
};
