import { ApolloClient, NormalizedCacheObject } from "@apollo/client/core";
import buildCurrentUserResolver from "@/apollo/user";
import { cache } from "./apollo/memory";
import { fullLink } from "./apollo/link";

export const apolloClient = new ApolloClient<NormalizedCacheObject>({
  cache,
  link: fullLink,
  connectToDevTools: true,
  resolvers: buildCurrentUserResolver(cache),
});
