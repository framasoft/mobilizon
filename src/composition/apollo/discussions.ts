import { useQuery } from "@vue/apollo-composable";
import { computed, unref } from "vue";
import { useCurrentUserClient } from "./user";
import type { Ref } from "vue";
import { IGroup } from "@/types/actor";
import { GROUP_DISCUSSIONS_LIST } from "@/graphql/discussion";

export function useGroupDiscussionsList(
  name: string | undefined | Ref<string | undefined>,
  options?: {
    discussionsPage?: number;
    discussionsLimit?: number;
  }
) {
  const { currentUser } = useCurrentUserClient();
  const { result, error, loading, onResult, onError, refetch } = useQuery<
    {
      group: Pick<
        IGroup,
        "id" | "preferredUsername" | "name" | "domain" | "discussions"
      >;
    },
    {
      name: string;
      discussionsPage?: number;
      discussionsLimit?: number;
    }
  >(
    GROUP_DISCUSSIONS_LIST,
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
