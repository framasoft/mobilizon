import { ApolloCache } from 'apollo-cache';
import { NormalizedCacheObject } from 'apollo-cache-inmemory';

export function buildCurrentUserResolver(cache: ApolloCache<NormalizedCacheObject>) {
  cache.writeData({
    data: {
      currentUser: {
        __typename: 'CurrentUser',
        id: null,
        email: null,
        isLoggedIn: false,
      },
    },
  });

  return {
    updateCurrentUser: (_, { id, email, isLoggedIn }, { cache }) => {
      const data = {
        Mutation: {
          currentUser: {
            id,
            email,
            isLoggedIn,
            __typename: 'CurrentUser',
          },
        },
      };

      cache.writeData({ data });
    },
  };
}
