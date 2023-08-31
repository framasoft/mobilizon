import {
  ApolloClient,
  ApolloQueryResult,
  NormalizedCacheObject,
  OperationVariables,
} from "@apollo/client/core";
import buildCurrentUserResolver from "@/apollo/user";
import { cache } from "./apollo/memory";
import { fullLink } from "./apollo/link";
import { UseQueryReturn } from "@vue/apollo-composable";

export const apolloClient = new ApolloClient<NormalizedCacheObject>({
  cache,
  link: fullLink,
  connectToDevTools: true,
  resolvers: buildCurrentUserResolver(cache),
});

export function waitApolloQuery<
  TResult = any,
  TVariables extends OperationVariables = OperationVariables,
>({
  onResult,
  onError,
}: UseQueryReturn<TResult, TVariables>): Promise<ApolloQueryResult<TResult>> {
  return new Promise((res, rej) => {
    const { off: offResult } = onResult((result) => {
      if (result.loading === false) {
        offResult();
        res(result);
      }
    });
    const { off: offError } = onError((error) => {
      offError();
      rej(error);
    });
  });
}
