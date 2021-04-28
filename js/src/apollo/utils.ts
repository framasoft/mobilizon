import {
  IntrospectionFragmentMatcher,
  NormalizedCacheObject,
} from "apollo-cache-inmemory";
import { AUTH_ACCESS_TOKEN, AUTH_REFRESH_TOKEN } from "@/constants";
import { REFRESH_TOKEN } from "@/graphql/auth";
import { saveTokenData } from "@/utils/auth";
import { ApolloClient } from "apollo-client";
import introspectionQueryResultData from "../../fragmentTypes.json";

export const fragmentMatcher = new IntrospectionFragmentMatcher({
  introspectionQueryResultData,
});

export async function refreshAccessToken(
  apolloClient: ApolloClient<NormalizedCacheObject>
): Promise<boolean> {
  // Remove invalid access token, so the next request is not authenticated
  localStorage.removeItem(AUTH_ACCESS_TOKEN);

  const refreshToken = localStorage.getItem(AUTH_REFRESH_TOKEN);

  console.log("Refreshing access token.");

  try {
    const res = await apolloClient.mutate({
      mutation: REFRESH_TOKEN,
      variables: {
        refreshToken,
      },
    });

    saveTokenData(res.data.refreshToken);

    return true;
  } catch (err) {
    return false;
  }
}
