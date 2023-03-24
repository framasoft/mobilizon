import { AUTH_USER_ACTOR_ID } from "@/constants";
import { UPDATE_CURRENT_ACTOR_CLIENT, IDENTITIES } from "@/graphql/actor";
import { IPerson } from "@/types/actor";
import { ICurrentUser } from "@/types/current-user.model";
import { apolloClient } from "@/vue-apollo";
import {
  provideApolloClient,
  useLazyQuery,
  useMutation,
} from "@vue/apollo-composable";
import { computed } from "vue";

export class NoIdentitiesException extends Error {}

function saveActorData(obj: IPerson): void {
  localStorage.setItem(AUTH_USER_ACTOR_ID, `${obj.id}`);
}

export async function changeIdentity(identity: IPerson): Promise<void> {
  if (!identity.id) return;
  const { mutate: updateCurrentActorClient } = provideApolloClient(
    apolloClient
  )(() => useMutation(UPDATE_CURRENT_ACTOR_CLIENT));

  updateCurrentActorClient(identity);
  if (identity.id) {
    saveActorData(identity);
  }
}

const { onResult: setIdentities, load: loadIdentities } = provideApolloClient(
  apolloClient
)(() => useLazyQuery<{ loggedUser: Pick<ICurrentUser, "actors"> }>(IDENTITIES));

/**
 * We fetch from localStorage the latest actor ID used,
 * then fetch the current identities to set in cache
 * the current identity used
 */
export async function initializeCurrentActor(): Promise<void> {
  const actorId = localStorage.getItem(AUTH_USER_ACTOR_ID);

  loadIdentities();

  setIdentities(async ({ data }) => {
    const identities = computed(() => data?.loggedUser?.actors);
    console.debug(
      "initializing current actor based on identities",
      identities.value
    );

    if (identities.value && identities.value.length < 1) {
      console.warn("Logged user has no identities!");
      throw new NoIdentitiesException();
    }
    const activeIdentity =
      (identities.value || []).find(
        (identity: IPerson | undefined) => identity?.id === actorId
      ) || ((identities.value || [])[0] as IPerson);

    if (activeIdentity) {
      await changeIdentity(activeIdentity);
    }
  });
}
