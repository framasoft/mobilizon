import { IDENTITIES, REGISTER_PERSON } from "@/graphql/actor";
import {
  CURRENT_USER_CLIENT,
  LOGGED_USER,
  SET_USER_SETTINGS,
  UPDATE_USER_LOCALE,
  USER_SETTINGS,
} from "@/graphql/user";
import { IPerson } from "@/types/actor";
import { ICurrentUser, IUser } from "@/types/current-user.model";
import { ActorType } from "@/types/enums";
import { ApolloCache, FetchResult } from "@apollo/client/core";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { computed } from "vue";

export function useCurrentUserClient() {
  const {
    result: currentUserResult,
    error,
    loading,
    onResult,
  } = useQuery<{
    currentUser: ICurrentUser;
  }>(CURRENT_USER_CLIENT);

  const currentUser = computed(() => currentUserResult.value?.currentUser);
  return { currentUser, error, loading, onResult };
}

export function useLoggedUser() {
  const { currentUser } = useCurrentUserClient();

  const { result, error, onError } = useQuery<{ loggedUser: IUser }>(
    LOGGED_USER,
    {},
    () => ({ enabled: currentUser.value?.id != null })
  );

  const loggedUser = computed(() => result.value?.loggedUser);
  return { loggedUser, error, onError };
}

export function useUserSettings() {
  const {
    result: userSettingsResult,
    error,
    loading,
  } = useQuery<{ loggedUser: IUser }>(USER_SETTINGS);

  const loggedUser = computed(() => userSettingsResult.value?.loggedUser);
  return { loggedUser, error, loading };
}

export async function doUpdateSetting(
  variables: Record<string, unknown>
): Promise<void> {
  useMutation<{ setUserSettings: string }>(SET_USER_SETTINGS, () => ({
    variables,
  }));
}

export function updateLocale() {
  return useMutation<{ id: string; locale: string }>(UPDATE_USER_LOCALE);
}

export function registerAccount() {
  return useMutation<
    { registerPerson: IPerson },
    {
      preferredUsername: string;
      name: string;
      summary: string;
      email: string;
    }
  >(REGISTER_PERSON, () => ({
    update: (
      store: ApolloCache<{ registerPerson: IPerson }>,
      { data: localData }: FetchResult,
      { context }
    ) => {
      if (context?.userAlreadyActivated) {
        const currentUserData = store.readQuery<{
          loggedUser: Pick<ICurrentUser, "actors" | "id">;
        }>({
          query: IDENTITIES,
        });

        if (currentUserData && localData) {
          const newPersonData = {
            ...localData.registerPerson,
            type: ActorType.PERSON,
          };

          store.writeQuery({
            query: IDENTITIES,
            data: {
              ...currentUserData.loggedUser,
              actors: [[...currentUserData.loggedUser.actors, newPersonData]],
            },
          });
        }
      }
    },
  }));
}
