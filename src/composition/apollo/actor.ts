import {
  CURRENT_ACTOR_CLIENT,
  GROUP_MEMBERSHIP_SUBSCRIPTION_CHANGED,
  IDENTITIES,
  PERSON_STATUS_GROUP,
} from "@/graphql/actor";
import { IPerson } from "@/types/actor";
import { ICurrentUser } from "@/types/current-user.model";
import { useLazyQuery, useQuery } from "@vue/apollo-composable";
import { computed, Ref, unref } from "vue";
import { useCurrentUserClient } from "./user";

export function useCurrentActorClient() {
  const {
    result: currentActorResult,
    error,
    loading,
  } = useQuery<{ currentActor: IPerson }>(CURRENT_ACTOR_CLIENT);
  const currentActor = computed<IPerson | undefined>(
    () => currentActorResult.value?.currentActor
  );
  return { currentActor, error, loading };
}

export function useLazyCurrentUserIdentities() {
  return useLazyQuery<{
    loggedUser: Pick<ICurrentUser, "actors">;
  }>(IDENTITIES);
}

export function useCurrentUserIdentities() {
  const { currentUser } = useCurrentUserClient();

  const { result, error, loading } = useQuery<{
    loggedUser: Pick<ICurrentUser, "actors">;
  }>(IDENTITIES, {}, () => ({
    enabled:
      currentUser.value?.id !== undefined &&
      currentUser.value?.id !== null &&
      currentUser.value?.isLoggedIn === true,
  }));

  const identities = computed(() => result.value?.loggedUser?.actors);
  return { identities, error, loading };
}

export function usePersonStatusGroup(
  groupFederatedUsername: string | undefined | Ref<string | undefined>
) {
  const { currentActor } = useCurrentActorClient();
  const { result, error, loading, subscribeToMore } = useQuery<{
    person: IPerson;
  }>(
    PERSON_STATUS_GROUP,
    () => ({
      id: currentActor.value?.id,
      group: unref(groupFederatedUsername),
    }),
    () => ({
      enabled:
        currentActor.value?.id !== undefined &&
        unref(groupFederatedUsername) !== undefined &&
        unref(groupFederatedUsername) !== "",
    })
  );
  subscribeToMore(() => ({
    document: GROUP_MEMBERSHIP_SUBSCRIPTION_CHANGED,
    variables: {
      actorId: currentActor.value?.id,
      group: unref(groupFederatedUsername),
    },
  }));
  const person = computed(() => result.value?.person);
  return { person, error, loading };
}
