import { PERSON_MEMBERSHIPS } from "@/graphql/actor";
import {
  CREATE_GROUP,
  DELETE_GROUP,
  FETCH_GROUP,
  LEAVE_GROUP,
  UPDATE_GROUP,
} from "@/graphql/group";
import { IGroup, IPerson } from "@/types/actor";
import { IAddress } from "@/types/address.model";
import { GroupVisibility, MemberRole, Openness } from "@/types/enums";
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
  const { result, error, loading, onResult, onError, refetch } = useQuery<
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
    () => ({
      enabled: unref(name) !== undefined && unref(name) !== "",
      fetchPolicy: "cache-and-network",
    })
  );
  const group = computed(() => result.value?.group);
  return { group, error, loading, onResult, onError, refetch };
}

export function useCreateGroup() {
  const { currentActor } = useCurrentActorClient();

  return useMutation<
    { createGroup: IGroup },
    {
      preferredUsername: string;
      name: string;
      summary?: string;
      avatar?: IMediaUploadWrapper;
      banner?: IMediaUploadWrapper;
    }
  >(CREATE_GROUP, () => ({
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

export function useUpdateGroup() {
  return useMutation<
    { updateGroup: IGroup },
    {
      id: string;
      name?: string;
      summary?: string;
      openness?: Openness;
      visibility?: GroupVisibility;
      physicalAddress?: IAddress;
      manuallyApprovesFollowers?: boolean;
    }
  >(UPDATE_GROUP);
}

export function useDeleteGroup(variables: { groupId: string }) {
  return useMutation<{ deleteGroup: IGroup }>(DELETE_GROUP, () => ({
    variables,
  }));
}

export function useLeaveGroup() {
  return useMutation<{ leaveGroup: { id: string } }>(LEAVE_GROUP);
}
