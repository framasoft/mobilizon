import Vue from "vue";
import VueApollo from "vue-apollo";
import { ApolloLink, Observable, split } from "apollo-link";
import {
  defaultDataIdFromObject,
  InMemoryCache,
  NormalizedCacheObject,
} from "apollo-cache-inmemory";
import { onError } from "apollo-link-error";
import { createLink } from "apollo-absinthe-upload-link";
import { ApolloClient } from "apollo-client";
import buildCurrentUserResolver from "@/apollo/user";
import { isServerError } from "@/types/apollo";
import { AUTH_ACCESS_TOKEN } from "@/constants";
import { logout } from "@/utils/auth";
import { Socket as PhoenixSocket } from "phoenix";
import * as AbsintheSocket from "@absinthe/socket";
import { createAbsintheSocketLink } from "@absinthe/socket-apollo-link";
import { getMainDefinition } from "apollo-utilities";
import fetch from "unfetch";
import { GRAPHQL_API_ENDPOINT, GRAPHQL_API_FULL_PATH } from "./api/_entrypoint";
import { fragmentMatcher, refreshAccessToken } from "./apollo/utils";

// Install the vue plugin
Vue.use(VueApollo);

let refreshingTokenPromise: Promise<boolean> | undefined;
let alreadyRefreshedToken = false;

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

const uploadLink = createLink({
  uri: httpEndpoint,
  fetch,
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

const errorLink = onError(
  ({ graphQLErrors, networkError, forward, operation }) => {
    if (
      isServerError(networkError) &&
      networkError.statusCode === 401 &&
      !alreadyRefreshedToken
    ) {
      if (!refreshingTokenPromise)
        refreshingTokenPromise = refreshAccessToken(apolloClient);

      return promiseToObservable(refreshingTokenPromise).flatMap(() => {
        refreshingTokenPromise = undefined;
        alreadyRefreshedToken = true;

        const context = operation.getContext();
        const oldHeaders = context.headers;

        operation.setContext({
          headers: {
            ...oldHeaders,
            authorization: generateTokenHeader(),
          },
        });

        return forward(operation);
      });
    }

    if (graphQLErrors) {
      graphQLErrors.map(({ message, locations, path }) =>
        console.log(
          `[GraphQL error]: Message: ${message}, Location: ${locations}, Path: ${path}`
        )
      );
    }

    if (networkError) {
      console.error(`[Network error]: ${networkError}`);
    }
  }
);

const fullLink = authMiddleware.concat(errorLink).concat(link);

const cache = new InMemoryCache({
  fragmentMatcher,
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

// Thanks: https://github.com/apollographql/apollo-link/issues/747#issuecomment-502676676
const promiseToObservable = <T>(promise: Promise<T>) =>
  new Observable<T>((subscriber) => {
    promise.then(
      (value) => {
        if (subscriber.closed) {
          return;
        }
        subscriber.next(value);
        subscriber.complete();
      },
      (err) => {
        console.error("Cannot refresh token.", err);

        subscriber.error(err);
        logout(apolloClient);
      }
    );
  });

// Manually call this when user log in
// export function onLogin(apolloClient) {
// if (apolloClient.wsClient) restartWebsockets(apolloClient.wsClient);
// }

// Manually call this when user log out
// export async function onLogout() {
// if (apolloClient.wsClient) restartWebsockets(apolloClient.wsClient);
// We don't reset store because we rely on currentUser & currentActor
// which are in the cache (even null). Maybe try to rerun cache init after resetStore?
// try {
//   await apolloClient.resetStore();
// } catch (e) {
//   // eslint-disable-next-line no-console
//   console.log('%cError on cache reset (logout)', 'color: orange;', e.message);
// }
// }
