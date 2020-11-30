declare global {
  interface GeolocationCoordinates {
    readonly accuracy: number;
    readonly altitude: number | null;
    readonly altitudeAccuracy: number | null;
    readonly heading: number | null;
    readonly latitude: number;
    readonly longitude: number;
    readonly speed: number | null;
  }

  interface GeolocationPosition {
    readonly coords: GeolocationCoordinates;
    readonly timestamp: number;
  }
}

export {};
