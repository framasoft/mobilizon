import Vue from "vue";
import VueApollo from "@vue/apollo-option";
import { onError } from "@apollo/client/link/error";
import { createLink } from "apollo-absinthe-upload-link";
import {
  ApolloClient,
  ApolloLink,
  defaultDataIdFromObject,
  fromPromise,
  InMemoryCache,
  NormalizedCacheObject,
  split,
} from "@apollo/client/core";
import { RetryLink } from "@apollo/client/link/retry";
import { Socket as PhoenixSocket } from "phoenix";
import * as AbsintheSocket from "@absinthe/socket";
import { createAbsintheSocketLink } from "@absinthe/socket-apollo-link";
import { getMainDefinition } from "@apollo/client/utilities";
import fetch from "unfetch";
import buildCurrentUserResolver from "@/apollo/user";
import { AUTH_ACCESS_TOKEN } from "@/constants";
import { logout } from "@/utils/auth";
import { GRAPHQL_API_ENDPOINT, GRAPHQL_API_FULL_PATH } from "./api/_entrypoint";
import {
  possibleTypes,
  typePolicies,
  refreshAccessToken,
} from "./apollo/utils";
import { GraphQLError } from "graphql";

// Install the vue plugin
Vue.use(VueApollo);

let isRefreshing = false;
let pendingRequests: any[] = [];

// Endpoints
const httpServer = GRAPHQL_API_ENDPOINT || "http://localhost:4000";
const httpEndpoint = GRAPHQL_API_FULL_PATH || `${httpServer}/api`;
const webSocketPrefix = process.env.NODE_ENV === "production" ? "wss" : "ws";
const wsEndpoint = `${webSocketPrefix}${httpServer.substring(
  httpServer.indexOf(":")
)}/graphql_socket`;

function generateTokenHeader() {
  const token = localStorage.getItem(AUTH_ACCESS_TOKEN);

  return token ? `Bearer ${token}` : null;
}

const authMiddleware = new ApolloLink((operation, forward) => {
  // add the authorization to the headers
  operation.setContext({
    headers: {
      authorization: generateTokenHeader(),
    },
  });

  if (forward) return forward(operation);

  return null;
});

const customFetch = async (uri: string, options: any) => {
  const response = await fetch(uri, options);
  if (response.status >= 400) {
    return Promise.reject(response.status);
  }
  return response;
};

const uploadLink = createLink({
  uri: httpEndpoint,
  fetch: customFetch,
});

const phoenixSocket = new PhoenixSocket(wsEndpoint, {
  params: () => {
    const token = localStorage.getItem(AUTH_ACCESS_TOKEN);
    if (token) {
      return { token };
    }
    return {};
  },
});

const absintheSocket = AbsintheSocket.create(phoenixSocket);
const wsLink = createAbsintheSocketLink(absintheSocket);

const link = split(
  // split based on operation type
  ({ query }) => {
    const definition = getMainDefinition(query);
    return (
      definition.kind === "OperationDefinition" &&
      definition.operation === "subscription"
    );
  },
  wsLink,
  uploadLink
);

const resolvePendingRequests = () => {
  pendingRequests.map((callback) => callback());
  pendingRequests = [];
};

const isAuthError = (graphQLError: GraphQLError | undefined) => {
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
  return graphQLError && [403, 401].includes(graphQLError.status_code);
};

const errorLink = onError(
  ({ graphQLErrors, networkError, forward, operation }) => {
    console.debug("We have an apollo error", [graphQLErrors, networkError]);
    if (
      graphQLErrors?.some((graphQLError) => isAuthError(graphQLError)) ||
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      networkError === 401
    ) {
      console.debug("It's a authorization error (statusCode 401)");
      let forwardOperation;

      if (!isRefreshing) {
        console.debug("Setting isRefreshing to true");
        isRefreshing = true;

        forwardOperation = fromPromise(
          refreshAccessToken(apolloClient)
            .then((res) => {
              if (res !== true) {
                // failed to refresh the token
                throw "Failed to refresh the token";
              }
              resolvePendingRequests();

              const context = operation.getContext();
              const oldHeaders = context.headers;

              operation.setContext({
                headers: {
                  ...oldHeaders,
                  authorization: generateTokenHeader(),
                },
              });
              return true;
            })
            .catch((e) => {
              console.debug("Something failed, let's logout", e);
              pendingRequests = [];
              // don't perform a logout since we don't have any working access/refresh tokens
              logout(apolloClient, false);
              return;
            })
            .finally(() => {
              isRefreshing = false;
            })
        ).filter((value) => Boolean(value));
      } else {
        forwardOperation = fromPromise(
          new Promise((resolve) => {
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            pendingRequests.push(() => resolve());
          })
        );
      }

      return forwardOperation.flatMap(() => forward(operation));
    }

    if (graphQLErrors) {
      graphQLErrors.map(
        (graphQLError: GraphQLError & { status_code?: number }) => {
          if (graphQLError?.status_code !== 401) {
            console.log(
              `[GraphQL error]: Message: ${graphQLError.message}, Location: ${graphQLError.locations}, Path: ${graphQLError.path}`
            );
          }
        }
      );
    }

    if (networkError) {
      console.error(`[Network error]: ${networkError}`);
    }
  }
);

const retryLink = new RetryLink();

const fullLink = authMiddleware
  .concat(retryLink)
  .concat(errorLink)
  .concat(link);

const cache = new InMemoryCache({
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

const apolloClient = new ApolloClient<NormalizedCacheObject>({
  cache,
  link: fullLink,
  connectToDevTools: true,
  resolvers: buildCurrentUserResolver(cache),
});

export default new VueApollo({
  defaultClient: apolloClient,
  errorHandler(error) {
    // eslint-disable-next-line no-console
    console.log(
      "%cError",
      "background: red; color: white; padding: 2px 4px; border-radius: 3px; font-weight: bold;",
      error.message
    );
    console.error(error);
  },
});
