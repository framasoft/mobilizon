import { useQuery } from "@vue/apollo-composable";
import { computed, unref } from "vue";
import { useCurrentUserClient } from "./user";
import type { Ref } from "vue";
import { IGroup } from "@/types/actor";
import { GROUP_RESOURCES_LIST } from "@/graphql/resources";

export function useGroupResourcesList(
  name: string | undefined | Ref<string | undefined>,
  options?: {
    resourcesPage?: number;
    resourcesLimit?: number;
  }
) {
  const { currentUser } = useCurrentUserClient();
  const { result, error, loading, onResult, onError, refetch } = useQuery<
    {
      group: Pick<
        IGroup,
        "id" | "preferredUsername" | "name" | "domain" | "resources"
      >;
    },
    {
      name: string;
      resourcesPage?: number;
      resourcesLimit?: number;
    }
  >(
    GROUP_RESOURCES_LIST,
    () => ({
      name: unref(name),
      ...options,
    }),
    () => ({
      enabled:
        unref(name) !== undefined &&
        unref(name) !== "" &&
        currentUser.value?.isLoggedIn,
      fetchPolicy: "cache-and-network",
    })
  );
  const group = computed(() => result.value?.group);
  return { group, error, loading, onResult, onError, refetch };
}
