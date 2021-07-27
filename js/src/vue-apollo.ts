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
import buildCurrentUserResolver from "@/apollo/user";
import { isServerError } from "@/types/apollo";
import { AUTH_ACCESS_TOKEN } from "@/constants";
import { logout } from "@/utils/auth";
import { Socket as PhoenixSocket } from "phoenix";
import * as AbsintheSocket from "@absinthe/socket";
import { createAbsintheSocketLink } from "@absinthe/socket-apollo-link";
import { getMainDefinition } from "@apollo/client/utilities";
import fetch from "unfetch";
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

const resolvePendingRequests = () => {
  pendingRequests.map((callback) => callback());
  pendingRequests = [];
};

const errorLink = onError(
  ({ graphQLErrors, networkError, forward, operation }) => {
    if (isServerError(networkError) && networkError?.statusCode === 401) {
      let forwardOperation;

      if (!isRefreshing) {
        isRefreshing = true;

        forwardOperation = fromPromise(
          refreshAccessToken(apolloClient)
            .then(() => {
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
            .catch(() => {
              pendingRequests = [];
              logout(apolloClient);
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

const fullLink = authMiddleware.concat(errorLink).concat(link);

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
