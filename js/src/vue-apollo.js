import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { ApolloLink } from 'apollo-link';
import { InMemoryCache, IntrospectionFragmentMatcher } from 'apollo-cache-inmemory';
import { createLink } from 'apollo-absinthe-upload-link';
import { createApolloClient, restartWebsockets } from 'vue-cli-plugin-apollo/graphql-client';
import { AUTH_TOKEN } from './constants';

// Install the vue plugin
Vue.use(VueApollo);

// Http endpoint
const httpEndpoint = process.env.VUE_APP_GRAPHQL_HTTP || 'http://localhost:4000/api';

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

  return forward(operation);
});

const uploadLink = createLink({
  uri: httpEndpoint,
});

// const link = ApolloLink.from([
//   uploadLink,
//   authMiddleware,
//   HttpLink,
// ]);

const link = authMiddleware.concat(uploadLink);

// Config
const defaultOptions = {
  // You can use `https` for secure connection (recommended in production)
  httpEndpoint,
  // You can use `wss` for secure connection (recommended in production)
  // Use `null` to disable subscriptions
  // wsEndpoint: process.env.VUE_APP_GRAPHQL_WS || 'ws://localhost:4000/graphql',
  // LocalStorage token
  tokenName: AUTH_TOKEN,
  // Enable Automatic Query persisting with Apollo Engine
  persisting: false,
  // Use websockets for everything (no HTTP)
  // You need to pass a `wsEndpoint` for this to work
  websocketsOnly: false,
  // Is being rendered on the server?
  ssr: false,
  cache,
  link,
  defaultHttpLink: false,
};

// Call this in the Vue app file
export function createProvider(options = {}) {
  // Create apollo client
  const { apolloClient, wsClient } = createApolloClient({
    ...defaultOptions,
    ...options,
  });
  apolloClient.wsClient = wsClient;

  // Create vue apollo provider
  const apolloProvider = new VueApollo({
    defaultClient: apolloClient,
    link,
    cache,
    connectToDevTools: true,
    defaultOptions: {
      $query: {
        // fetchPolicy: 'cache-and-network',
      },
    },
    errorHandler(error) {
      // eslint-disable-next-line no-console
      console.log('%cError', 'background: red; color: white; padding: 2px 4px; border-radius: 3px; font-weight: bold;', error.message);
    },
  });

  return apolloProvider;
}

// Manually call this when user log in
export async function onLogin(apolloClient, token) {
  if (typeof localStorage !== 'undefined' && token) {
    localStorage.setItem(AUTH_TOKEN, token);
  }
  if (apolloClient.wsClient) restartWebsockets(apolloClient.wsClient);
  try {
    await apolloClient.resetStore();
  } catch (e) {
    // eslint-disable-next-line no-console
    console.log('%cError on cache reset (login)', 'color: orange;', e.message);
  }
}

// Manually call this when user log out
export async function onLogout(apolloClient) {
  if (typeof localStorage !== 'undefined') {
    localStorage.removeItem(AUTH_TOKEN);
  }
  if (apolloClient.wsClient) restartWebsockets(apolloClient.wsClient);
  try {
    await apolloClient.resetStore();
  } catch (e) {
    // eslint-disable-next-line no-console
    console.log('%cError on cache reset (logout)', 'color: orange;', e.message);
  }
}
