import { defaultDataIdFromObject, InMemoryCache } from "@apollo/client/core";
import { possibleTypes, typePolicies } from "./utils";

export const cache = new InMemoryCache({
  addTypename: true,
  typePolicies,
  possibleTypes,
  dataIdFromObject: (object: any) => {
    if (object.__typename === "Address") {
      return object.origin_id;
    }
    return defaultDataIdFromObject(object);
  },
});
