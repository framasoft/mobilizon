import { ApolloCache } from 'apollo-cache';
import { NormalizedCacheObject } from 'apollo-cache-inmemory';
import { ICurrentUserRole } from '@/types/current-user.model';

export function buildCurrentUserResolver(cache: ApolloCache<NormalizedCacheObject>) {
  cache.writeData({
    data: {
      currentUser: {
        __typename: 'CurrentUser',
        id: null,
        email: null,
        isLoggedIn: false,
        role: ICurrentUserRole.USER,
      },
    },
  });

  return {
    Mutation: {
      updateCurrentUser: (_, { id, email, isLoggedIn, role }, { cache }) => {
        const data = {
          currentUser: {
            id,
            email,
            isLoggedIn,
            role,
            __typename: 'CurrentUser',
          },
        };

        cache.writeData({ data });
      },
    },
  };
}
