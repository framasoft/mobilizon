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
      currentActor: {
        __typename: 'CurrentActor',
        id: null,
        preferredUsername: null,
        name: null,
        avatar: null,
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
      updateCurrentActor: (_, { id, preferredUsername, avatar, name }, { cache }) => {
        const data = {
          currentActor: {
            id,
            preferredUsername,
            avatar,
            name,
            __typename: 'CurrentActor',
          },
        };

        cache.writeData({ data });
      },
    },
  };
}
