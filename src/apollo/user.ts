import { CURRENT_ACTOR_CLIENT } from "@/graphql/actor";
import { CURRENT_USER_LOCATION_CLIENT } from "@/graphql/location";
import { CURRENT_USER_CLIENT } from "@/graphql/user";
import { ICurrentUserRole } from "@/types/enums";
import { ApolloCache, NormalizedCacheObject } from "@apollo/client/cache";
import { Resolvers } from "@apollo/client/core/types";

export default function buildCurrentUserResolver(
  cache: ApolloCache<NormalizedCacheObject>
): Resolvers {
  cache?.writeQuery({
    query: CURRENT_USER_CLIENT,
    data: {
      currentUser: {
        __typename: "CurrentUser",
        id: null,
        email: null,
        isLoggedIn: false,
        role: ICurrentUserRole.USER,
      },
    },
  });

  cache?.writeQuery({
    query: CURRENT_ACTOR_CLIENT,
    data: {
      currentActor: {
        __typename: "CurrentActor",
        id: null,
        preferredUsername: null,
        name: null,
        avatar: null,
      },
    },
  });

  cache?.writeQuery({
    query: CURRENT_USER_LOCATION_CLIENT,
    data: {
      currentUserLocation: {
        lat: null,
        lon: null,
        accuracy: null,
        isIPLocation: null,
        name: null,
        picture: null,
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

        localCache.writeQuery({ data, query: CURRENT_USER_CLIENT });
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

        localCache.writeQuery({ data, query: CURRENT_ACTOR_CLIENT });
      },
      updateCurrentUserLocation: (
        _: any,
        {
          lat,
          lon,
          accuracy,
          isIPLocation,
          name,
          picture,
        }: {
          lat: number;
          lon: number;
          accuracy: number;
          isIPLocation: boolean;
          name: string;
          picture: any;
        },
        { cache: localCache }: { cache: ApolloCache<NormalizedCacheObject> }
      ) => {
        const data = {
          currentUserLocation: {
            lat,
            lon,
            accuracy,
            isIPLocation,
            name,
            picture,
            __typename: "CurrentUserLocation",
          },
        };

        localCache.writeQuery({ data, query: CURRENT_USER_LOCATION_CLIENT });
      },
    },
  };
}
