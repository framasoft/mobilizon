import ngeohash from "ngeohash";

import { IAddress, Address } from "@/types/address.model";
import { LocationType } from "@/types/user-location.model";
import { IUserPreferredLocation } from "@/types/current-user.model";

const GEOHASH_DEPTH = 9; // put enough accuracy, radius will be used anyway

export const addressToLocation = (
  address: IAddress
): LocationType | undefined => {
  if (!address.geom) return undefined;
  const arr = address.geom.split(";");
  if (arr.length < 2) return undefined;
  return {
    lon: parseFloat(arr[0]),
    lat: parseFloat(arr[1]),
    name: address.description,
  };
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

export const storeLocationInLocal = (location: IAddress | null): undefined => {
  if (location) {
    window.localStorage.setItem("location", JSON.stringify(location));
  } else {
    window.localStorage.removeItem("location");
  }
};

export const getLocationFromLocal = (): IAddress | null => {
  const locationString = window.localStorage.getItem("location");
  if (!locationString) {
    return null;
  }
  const location = JSON.parse(locationString) as IAddress;
  if (!location.description || !location.geom) {
    return null;
  }
  return location;
};

export const storeRadiusInLocal = (radius: number | null): undefined => {
  if (radius) {
    window.localStorage.setItem("radius", radius.toString());
  } else {
    window.localStorage.removeItem("radius");
  }
};

export const getRadiusFromLocal = (): IAddress | null => {
  const locationString = window.localStorage.getItem("location");
  if (!locationString) {
    return null;
  }
  const location = JSON.parse(locationString) as IAddress;
  if (!location.description || !location.geom) {
    return null;
  }
  return location;
};

export const storeUserLocationAndRadiusFromUserSettings = (
  location: IUserPreferredLocation | null
): undefined => {
  if (location) {
    const latlon = geoHashToCoords(location.geohash);
    if (latlon) {
      storeLocationInLocal({
        ...new Address(),
        geom: `${latlon.longitude};${latlon.latitude}`,
        description: location.name || "",
        type: "administrative",
      });
    }
    if (location.range) {
      storeRadiusInLocal(location.range);
    } else {
      console.debug("user has not set a radius");
    }
  } else {
    console.debug("user has not set a location");
  }
};
