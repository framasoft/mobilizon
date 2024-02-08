import { GROUP_MEMBERS } from "@/graphql/member";
import { IGroup } from "@/types/actor";
import { MemberRole } from "@/types/enums";
import { useQuery } from "@vue/apollo-composable";
import { computed } from "vue";
import type { Ref } from "vue";

type useGroupMembersOptions = {
  membersPage?: number;
  membersLimit?: number;
  roles?: MemberRole[];
  enabled?: Ref<boolean>;
  name?: string;
};

export function useGroupMembers(
  groupName: Ref<string>,
  options: useGroupMembersOptions = {}
) {
  const { result, error, loading, onResult, onError, refetch, fetchMore } =
    useQuery<
      {
        group: IGroup;
      },
      {
        name: string;
        membersPage?: number;
        membersLimit?: number;
      }
    >(
      GROUP_MEMBERS,
      () => ({
        groupName: groupName.value,
        page: options.membersPage,
        limit: options.membersLimit,
        name: options.name,
      }),
      () => ({
        enabled: !!groupName.value && options.enabled?.value,
        fetchPolicy: "cache-and-network",
      })
    );
  const members = computed(() => result.value?.group?.members);
  return { members, error, loading, onResult, onError, refetch, fetchMore };
}
