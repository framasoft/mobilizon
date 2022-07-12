import { PERSON_MEMBERSHIPS } from "@/graphql/actor";
import {
  CREATE_GROUP,
  DELETE_GROUP,
  FETCH_GROUP,
  LEAVE_GROUP,
  UPDATE_GROUP,
} from "@/graphql/group";
import { IGroup, IPerson } from "@/types/actor";
import { MemberRole } from "@/types/enums";
import { IMediaUploadWrapper } from "@/types/media.model";
import { ApolloCache, FetchResult, InMemoryCache } from "@apollo/client/core";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { computed, Ref, unref } from "vue";
import { useCurrentActorClient } from "./actor";

type useGroupOptions = {
  beforeDateTime?: string | Date;
  afterDateTime?: string | Date;
  organisedEventsPage?: number;
  organisedEventsLimit?: number;
  postsPage?: number;
  postsLimit?: number;
  membersPage?: number;
  membersLimit?: number;
  discussionsPage?: number;
  discussionsLimit?: number;
};

export function useGroup(
  name: string | undefined | Ref<string | undefined>,
  options: useGroupOptions = {}
) {
  console.debug("using group with", name);

  const { result, error, loading, onError, refetch } = useQuery<
    {
      group: IGroup;
    },
    {
      name: string;
      beforeDateTime?: string | Date;
      afterDateTime?: string | Date;
      organisedEventsPage?: number;
      organisedEventsLimit?: number;
      postsPage?: number;
      postsLimit?: number;
      membersPage?: number;
      membersLimit?: number;
      discussionsPage?: number;
      discussionsLimit?: number;
    }
  >(
    FETCH_GROUP,
    () => ({
      name: unref(name),
      ...options,
    }),
    () => ({ enabled: unref(name) !== undefined })
  );
  const group = computed(() => result.value?.group);
  return { group, error, loading, onError, refetch };
}

export function useCreateGroup(variables: {
  preferredUsername: string;
  name: string;
  summary?: string;
  avatar?: IMediaUploadWrapper;
  banner?: IMediaUploadWrapper;
}) {
  const { currentActor } = useCurrentActorClient();

  return useMutation(CREATE_GROUP, () => ({
    variables,
    update: (store: ApolloCache<InMemoryCache>, { data }: FetchResult) => {
      const query = {
        query: PERSON_MEMBERSHIPS,
        variables: {
          id: currentActor.value?.id,
        },
      };
      const membershipData = store.readQuery<{ person: IPerson }>(query);
      if (!membershipData) return;
      if (!currentActor.value) return;
      const { person } = membershipData;
      person.memberships?.elements.push({
        parent: data?.createGroup,
        role: MemberRole.ADMINISTRATOR,
        actor: currentActor.value,
        insertedAt: new Date().toString(),
        updatedAt: new Date().toString(),
      });
      store.writeQuery({ ...query, data: { person } });
    },
  }));
}

export function useUpdateGroup(variables: any) {
  return useMutation<{ updateGroup: IGroup }>(UPDATE_GROUP, () => ({
    variables,
  }));
}

export function useDeleteGroup(variables: { groupId: string }) {
  return useMutation<{ deleteGroup: IGroup }>(DELETE_GROUP, () => ({
    variables,
  }));
}

export function useLeaveGroup() {
  return useMutation<{ leaveGroup: { id: string } }>(LEAVE_GROUP);
}
