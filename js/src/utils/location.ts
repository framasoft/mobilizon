import ngeohash from "ngeohash";

const GEOHASH_DEPTH = 9; // put enough accuracy, radius will be used anyway

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
  geohash: string | undefined
): { latitude: number; longitude: number } | undefined => {
  if (!geohash) return undefined;
  const { latitude, longitude } = ngeohash.decode(geohash);
  return latitude && longitude ? { latitude, longitude } : undefined;
};
