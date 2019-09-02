import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { ApolloLink, Observable } from 'apollo-link';
import { InMemoryCache, IntrospectionFragmentMatcher } from 'apollo-cache-inmemory';
import { onError } from 'apollo-link-error';
import { createLink } from 'apollo-absinthe-upload-link';
import { GRAPHQL_API_ENDPOINT, GRAPHQL_API_FULL_PATH } from './api/_entrypoint';
import { ApolloClient } from 'apollo-client';
import { DollarApollo } from 'vue-apollo/types/vue-apollo';
import { buildCurrentUserResolver } from '@/apollo/user';
import { isServerError } from '@/types/apollo';
import { inspect } from 'util';
import { REFRESH_TOKEN } from '@/graphql/auth';
import { AUTH_ACCESS_TOKEN, AUTH_REFRESH_TOKEN } from '@/constants';
import { logout, saveTokenData } from '@/utils/auth';

// Install the vue plugin
Vue.use(VueApollo);

// Http endpoint
const httpServer = GRAPHQL_API_ENDPOINT || 'http://localhost:4000';
const httpEndpoint = GRAPHQL_API_FULL_PATH || `${httpServer}/api`;

const fragmentMatcher = new IntrospectionFragmentMatcher({
  introspectionQueryResultData: {
    __schema: {
      types: [
        {
          kind: 'UNION',
          name: 'SearchResult',
          possibleTypes: [
            { name: 'Event' },
            { name: 'Person' },
            { name: 'Group' },
          ],
        },
        {
          kind: 'INTERFACE',
          name: 'Actor',
          possibleTypes: [
            { name: 'Person' },
            { name: 'Group' },
          ],
        },
      ],
    },
  },
});

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
});

let refreshingTokenPromise: Promise<boolean> | undefined;
let alreadyRefreshedToken = false;
const errorLink = onError(({ graphQLErrors, networkError, forward, operation }) => {
  if (isServerError(networkError) && networkError.statusCode === 401 && !alreadyRefreshedToken) {
    if (!refreshingTokenPromise) refreshingTokenPromise = refreshAccessToken();

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
    graphQLErrors.forEach(({ message, locations, path }) =>
      console.log(`[GraphQL error]: Message: ${message}, Location: ${locations}, Path: ${path}`),
    );
  }

  if (networkError) console.log(`[Network error]: ${networkError}`);
});

const link = authMiddleware
  .concat(errorLink)
  .concat(uploadLink);

const cache = new InMemoryCache({ fragmentMatcher });

const apolloClient = new ApolloClient({
  cache,
  link,
  connectToDevTools: true,
  resolvers: buildCurrentUserResolver(cache),
});

export const apolloProvider = new VueApollo({
  defaultClient: apolloClient,
  errorHandler(error) {
    // eslint-disable-next-line no-console
    console.log('%cError', 'background: red; color: white; padding: 2px 4px; border-radius: 3px; font-weight: bold;', error.message);
  },
});

// Manually call this when user log in
export function onLogin(apolloClient) {
  // if (apolloClient.wsClient) restartWebsockets(apolloClient.wsClient);
}

// Manually call this when user log out
export async function onLogout() {
  // if (apolloClient.wsClient) restartWebsockets(apolloClient.wsClient);

  try {
    await apolloClient.resetStore();
  } catch (e) {
    // eslint-disable-next-line no-console
    console.log('%cError on cache reset (logout)', 'color: orange;', e.message);
  }
}

async function refreshAccessToken() {
  // Remove invalid access token, so the next request is not authenticated
  localStorage.removeItem(AUTH_ACCESS_TOKEN);

  const refreshToken = localStorage.getItem(AUTH_REFRESH_TOKEN);

  console.log('Refreshing access token.');

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

function generateTokenHeader() {
  const token = localStorage.getItem(AUTH_ACCESS_TOKEN);

  return token ? `Bearer ${token}` : null;
}

// Thanks: https://github.com/apollographql/apollo-link/issues/747#issuecomment-502676676
const promiseToObservable = <T> (promise: Promise<T>) => {
  return new Observable<T>((subscriber) => {
    promise.then(
      (value) => {
        if (subscriber.closed) {
          return;
        }
        subscriber.next(value);
        subscriber.complete();
      },
      (err) => {
        console.error('Cannot refresh token.', err);

        subscriber.error(err);
        logout(apolloClient);
      },
    );
  });
};
