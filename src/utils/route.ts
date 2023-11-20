import { RouteQueryTransformer } from "vue-use-route-query";

export const arrayTransformer: RouteQueryTransformer<string[]> = {
  fromQuery(query: string) {
    return query.split(",");
  },
  toQuery(value: string[]) {
    return value.join(",");
  },
};
