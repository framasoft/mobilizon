import { ICurrentUserRole } from "@/types/enums";
import { ApolloCache } from "apollo-cache";
import { NormalizedCacheObject } from "apollo-cache-inmemory";
import { Resolvers } from "apollo-client/core/types";

export default function buildCurrentUserResolver(
  cache: ApolloCache<NormalizedCacheObject>
): Resolvers {
  cache.writeData({
    data: {
      currentUser: {
        __typename: "CurrentUser",
        id: null,
        email: null,
        isLoggedIn: false,
        role: ICurrentUserRole.USER,
      },
      currentActor: {
        __typename: "CurrentActor",
        id: null,
        preferredUsername: null,
        name: null,
        avatar: null,
      },
    },
  });

  return {
    Mutation: {
      updateCurrentUser: (
        _: any,
        {
          id,
          email,
          isLoggedIn,
          role,
        }: { id: string; email: string; isLoggedIn: boolean; role: string },
        { cache: localCache }: { cache: ApolloCache<NormalizedCacheObject> }
      ) => {
        const data = {
          currentUser: {
            id,
            email,
            isLoggedIn,
            role,
            __typename: "CurrentUser",
          },
        };

        localCache.writeData({ data });
      },
      updateCurrentActor: (
        _: any,
        {
          id,
          preferredUsername,
          avatar,
          name,
        }: {
          id: string;
          preferredUsername: string;
          avatar: string;
          name: string;
        },
        { cache: localCache }: { cache: ApolloCache<NormalizedCacheObject> }
      ) => {
        const data = {
          currentActor: {
            id,
            preferredUsername,
            avatar,
            name,
            __typename: "CurrentActor",
          },
        };

        localCache.writeData({ data });
      },
    },
  };
}
