import { REVERSE_GEOCODE } from "@/graphql/address";
import { useLazyQuery } from "@vue/apollo-composable";
import { IAddress } from "@/types/address.model";

type reverseGeoCodeType = {
  latitude: number;
  longitude: number;
  zoom: number;
  locale: string;
};

export function useReverseGeocode() {
  return useLazyQuery<{ reverseGeocode: IAddress[] }, reverseGeoCodeType>(
    REVERSE_GEOCODE
  );
}
