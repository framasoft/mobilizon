import { AUTH_ACCESS_TOKEN, AUTH_REFRESH_TOKEN } from "@/constants";
import { REFRESH_TOKEN } from "@/graphql/auth";
import { IFollower } from "@/types/actor/follower.model";
import { IParticipant } from "@/types/participant.model";
import { Paginate } from "@/types/paginate";
import { saveTokenData } from "@/utils/auth";
import {
  ApolloClient,
  FieldPolicy,
  NormalizedCacheObject,
  Reference,
  TypePolicies,
} from "@apollo/client/core";
import introspectionQueryResultData from "../../fragmentTypes.json";
import { IMember } from "@/types/actor/member.model";
import { IComment } from "@/types/comment.model";
import { IEvent } from "@/types/event.model";
import { IActivity } from "@/types/activity.model";
import uniqBy from "lodash/uniqBy";

type possibleTypes = { name: string };
type schemaType = {
  kind: string;
  name: string;
  possibleTypes: possibleTypes[];
};

// eslint-disable-next-line no-underscore-dangle
const types = introspectionQueryResultData.__schema.types as schemaType[];
export const possibleTypes = types.reduce((acc, type) => {
  if (type.kind === "INTERFACE") {
    acc[type.name] = type.possibleTypes.map(({ name }) => name);
  }
  return acc;
}, {} as Record<string, string[]>);

const replaceMergePolicy = <TExisting = any, TIncoming = any>(
  _existing: TExisting,
  incoming: TIncoming
): TIncoming => incoming;

export const typePolicies: TypePolicies = {
  Discussion: {
    fields: {
      comments: paginatedLimitPagination<IComment>(),
    },
  },
  Group: {
    fields: {
      organizedEvents: paginatedLimitPagination([
        "afterDatetime",
        "beforeDatetime",
      ]),
      activity: paginatedLimitPagination<IActivity>(["type", "author"]),
    },
  },
  Person: {
    fields: {
      organizedEvents: paginatedLimitPagination<IEvent>(),
      participations: paginatedLimitPagination<IParticipant>(["eventId"]),
      memberships: paginatedLimitPagination<IMember>(["group"]),
    },
  },
  Event: {
    fields: {
      participants: paginatedLimitPagination<IParticipant>(["roles"]),
      comments: pageLimitPagination<IComment>(),
      relatedEvents: pageLimitPagination<IEvent>(),
      options: { merge: replaceMergePolicy },
      participantStats: { merge: replaceMergePolicy },
    },
  },
  RootQueryType: {
    fields: {
      relayFollowers: paginatedLimitPagination<IFollower>(),
      relayFollowings: paginatedLimitPagination<IFollower>([
        "orderBy",
        "direction",
      ]),
      events: paginatedLimitPagination(),
      groups: paginatedLimitPagination([
        "preferredUsername",
        "name",
        "domain",
        "local",
        "suspended",
      ]),
      persons: paginatedLimitPagination([
        "preferredUsername",
        "name",
        "domain",
        "local",
        "suspended",
      ]),
    },
  },
};

export async function refreshAccessToken(
  apolloClient: ApolloClient<NormalizedCacheObject>
): Promise<boolean> {
  // Remove invalid access token, so the next request is not authenticated
  localStorage.removeItem(AUTH_ACCESS_TOKEN);

  const refreshToken = localStorage.getItem(AUTH_REFRESH_TOKEN);

  if (!refreshToken) {
    console.debug("Refresh token not found");
    return false;
  }

  console.log("Refreshing access token.");

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
    console.debug("Failed to refresh token");
    return false;
  }
}

type KeyArgs = FieldPolicy<any>["keyArgs"];

export function pageLimitPagination<T = Reference>(
  keyArgs: KeyArgs = false
): FieldPolicy<T[]> {
  return {
    keyArgs,
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    merge(existing, incoming, { args }) {
      if (!incoming) return existing;
      if (!existing) return incoming; // existing will be empty the first time

      return doMerge(existing as Array<T>, incoming as Array<T>, args);
    },
  };
}

export function paginatedLimitPagination<T = Paginate<any>>(
  keyArgs: KeyArgs = false
): FieldPolicy<Paginate<T>> {
  return {
    keyArgs,
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    merge(existing, incoming, { args }) {
      if (!incoming) return existing;
      if (!existing) return incoming; // existing will be empty the first time

      return {
        total: incoming.total,
        elements: doMerge(existing.elements, incoming.elements, args),
      };
    },
  };
}

function doMerge<T = any>(
  existing: Array<T>,
  incoming: Array<T>,
  args: Record<string, any> | null
): Array<T> {
  const merged = existing && Array.isArray(existing) ? existing.slice(0) : [];
  const previous = incoming && Array.isArray(incoming) ? incoming.slice(0) : [];
  let res;
  if (args) {
    // Assume an page of 1 if args.page omitted.
    const { page = 1, limit = 10 } = args;
    for (let i = 0; i < previous.length; ++i) {
      merged[(page - 1) * limit + i] = previous[i];
    }
    res = merged;
  } else {
    // It's unusual (probably a mistake) for a paginated field not
    // to receive any arguments, so you might prefer to throw an
    // exception here, instead of recovering by appending incoming
    // onto the existing array.
    res = [...merged, ...previous];
    // eslint-disable-next-line no-underscore-dangle
    res = uniqBy(res, (elem: any) => elem.__ref);
  }
  return res;
}
