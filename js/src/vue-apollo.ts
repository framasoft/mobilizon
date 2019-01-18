import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { ApolloLink } from 'apollo-link';
import { InMemoryCache, IntrospectionFragmentMatcher } from 'apollo-cache-inmemory';
import { createLink } from 'apollo-absinthe-upload-link';
import { AUTH_TOKEN } from './constants';
import { GRAPHQL_API_ENDPOINT, GRAPHQL_API_FULL_PATH } from './api/_entrypoint';
import { withClientState } from 'apollo-link-state';
import { currentUser } from '@/apollo/user';
import merge from 'lodash/merge';
import { ApolloClient } from 'apollo-client';
import { DollarApollo } from 'vue-apollo/types/vue-apollo';

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
            { name: 'Actor' },
          ],
        }, // this is an example, put your INTERFACE and UNION kinds here!
      ],
    },
  },
});

const cache = new InMemoryCache({ fragmentMatcher });

const authMiddleware = new ApolloLink((operation, forward) => {
  // add the authorization to the headers
  const token = localStorage.getItem(AUTH_TOKEN);
  operation.setContext({
    headers: {
      authorization: token ? `Bearer ${token}` : null,
    },
  });

  if (forward) return forward(operation);

  return null;
});

const uploadLink = createLink({
  uri: httpEndpoint,
});

const stateLink = withClientState({
  ...merge(currentUser),
  cache,
});

const link = stateLink.concat(authMiddleware).concat(uploadLink);

const apolloClient = new ApolloClient({
  cache,
  link,
  connectToDevTools: true,
});

apolloClient.onResetStore(stateLink.writeDefaults as any);

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
export async function onLogout(apolloClient: DollarApollo<any>) {
  // if (apolloClient.wsClient) restartWebsockets(apolloClient.wsClient);

  try {
    await apolloClient.provider.defaultClient.resetStore();
  } catch (e) {
    // eslint-disable-next-line no-console
    console.log('%cError on cache reset (logout)', 'color: orange;', e.message);
  }
}
