<template>
  <div>
    <breadcrumbs-nav
      v-if="group"
      :links="[
        {
          name: RouteName.GROUP,
          params: { preferredUsername: usernameWithDomain(group) },
          text: displayName(group),
        },
        {
          name: RouteName.GROUP_SETTINGS,
          params: { preferredUsername: usernameWithDomain(group) },
          text: t('Settings'),
        },
        {
          name: RouteName.GROUP_MEMBERS_SETTINGS,
          params: { preferredUsername: usernameWithDomain(group) },
          text: t('Members'),
        },
      ]"
    />
    <o-loading :active="groupMembersLoading" />
    <section
      class="container mx-auto section"
      v-if="group && isCurrentActorAGroupAdmin"
    >
      <h1>{{ t("Group Members") }} ({{ group.members.total }})</h1>
      <form @submit.prevent="inviteMember">
        <o-field
          :label="t('Invite a new member')"
          custom-class="add-relay"
          label-for="new-member-field"
          horizontal
        >
          <o-field
            grouped
            expanded
            size="large"
            :type="inviteError ? 'is-danger' : null"
            :message="inviteError"
          >
            <p class="control">
              <o-input
                id="new-member-field"
                v-model="newMemberUsername"
                :placeholder="t(`Ex: someone{'@'}mobilizon.org`)"
              />
            </p>
            <p class="control">
              <o-button variant="primary" native-type="submit">{{
                t("Invite member")
              }}</o-button>
            </p>
          </o-field>
        </o-field>
      </form>
      <o-field
        class="my-2"
        :label="t('Status')"
        horizontal
        label-for="group-members-status-filter"
      >
        <o-select v-model="roles" id="group-members-status-filter">
          <option :value="undefined">
            {{ t("Everything") }}
          </option>
          <option :value="MemberRole.ADMINISTRATOR">
            {{ t("Administrator") }}
          </option>
          <option :value="MemberRole.MODERATOR">
            {{ t("Moderator") }}
          </option>
          <option :value="MemberRole.MEMBER">
            {{ t("Member") }}
          </option>
          <option :value="MemberRole.INVITED">
            {{ t("Invited") }}
          </option>
          <option :value="MemberRole.NOT_APPROVED">
            {{ t("Not approved") }}
          </option>
          <option :value="MemberRole.REJECTED">
            {{ t("Rejected") }}
          </option>
        </o-select>
      </o-field>
      <o-table
        v-if="members"
        :data="members.elements"
        ref="queueTable"
        :loading="groupMembersLoading"
        paginated
        backend-pagination
        v-model:current-page="page"
        :pagination-simple="true"
        :aria-next-label="t('Next page')"
        :aria-previous-label="t('Previous page')"
        :aria-page-label="t('Page')"
        :aria-current-label="t('Current page')"
        :total="members.total"
        :per-page="MEMBERS_PER_PAGE"
        backend-sorting
        :default-sort-direction="'desc'"
        :default-sort="['insertedAt', 'desc']"
        @page-change="loadMoreMembers"
        @sort="(field: string, order: string) => emit('sort', field, order)"
      >
        <o-table-column
          field="actor.preferredUsername"
          :label="t('Member')"
          v-slot="props"
        >
          <article class="flex">
            <figure v-if="props.row.actor.avatar" class="h-10 w-10">
              <img
                class="rounded-full object-cover h-full"
                :src="props.row.actor.avatar.url"
                :alt="props.row.actor.avatar.alt || ''"
                height="48"
                width="48"
              />
            </figure>
            <AccountCircle v-else :size="48" />

            <div class="">
              <div class="text-start">
                <span v-if="props.row.actor.name">{{
                  props.row.actor.name
                }}</span
                ><br />
                <span class="">@{{ usernameWithDomain(props.row.actor) }}</span>
              </div>
            </div>
          </article>
        </o-table-column>
        <o-table-column field="role" :label="t('Role')" v-slot="props">
          <tag
            variant="info"
            v-if="props.row.role === MemberRole.ADMINISTRATOR"
          >
            {{ t("Administrator") }}
          </tag>
          <tag
            variant="info"
            v-else-if="props.row.role === MemberRole.MODERATOR"
          >
            {{ t("Moderator") }}
          </tag>
          <tag v-else-if="props.row.role === MemberRole.MEMBER">
            {{ t("Member") }}
          </tag>
          <tag
            variant="warning"
            v-else-if="props.row.role === MemberRole.NOT_APPROVED"
          >
            {{ t("Not approved") }}
          </tag>
          <tag
            variant="danger"
            v-else-if="props.row.role === MemberRole.REJECTED"
          >
            {{ t("Rejected") }}
          </tag>
          <tag
            variant="warning"
            v-else-if="props.row.role === MemberRole.INVITED"
          >
            {{ t("Invited") }}
          </tag>
        </o-table-column>
        <o-table-column field="insertedAt" :label="t('Date')" v-slot="props">
          <span class="has-text-centered">
            {{ formatDateString(props.row.insertedAt) }}<br />{{
              formatTimeString(props.row.insertedAt)
            }}
          </span>
        </o-table-column>
        <o-table-column field="actions" :label="t('Actions')" v-slot="props">
          <div
            class="flex flex-wrap gap-2"
            v-if="props.row.actor.id !== currentActor?.id"
          >
            <o-button
              variant="success"
              v-if="props.row.role === MemberRole.NOT_APPROVED"
              @click="approveMember({ memberId: props.row.id })"
              icon-left="check"
              >{{ t("Approve member") }}</o-button
            >
            <o-button
              variant="danger"
              v-if="props.row.role === MemberRole.NOT_APPROVED"
              @click="rejectMember(props.row)"
              icon-left="exit-to-app"
              >{{ t("Reject member") }}</o-button
            >
            <o-button
              v-if="
                [MemberRole.MEMBER, MemberRole.MODERATOR].includes(
                  props.row.role
                )
              "
              @click="promoteMember(props.row)"
              icon-left="chevron-double-up"
              >{{ t("Promote") }}</o-button
            >
            <o-button
              v-if="
                [MemberRole.ADMINISTRATOR, MemberRole.MODERATOR].includes(
                  props.row.role
                )
              "
              @click="demoteMember(props.row)"
              icon-left="chevron-double-down"
              >{{ t("Demote") }}</o-button
            >
            <o-button
              v-if="props.row.role === MemberRole.MEMBER"
              @click="removeMember(props.row)"
              variant="danger"
              icon-left="exit-to-app"
              >{{ t("Remove") }}</o-button
            >
          </div>
        </o-table-column>
        <template #empty>
          <empty-content icon="account" inline>
            {{ t("No member matches the filters") }}
          </empty-content>
        </template>
      </o-table>
    </section>
    <o-notification v-else-if="!groupMembersLoading && group">
      {{ t("You are not an administrator for this group.") }}
    </o-notification>
  </div>
</template>

<script lang="ts" setup>
import { MemberRole } from "@/types/enums";
import { IMember } from "@/types/actor/member.model";
import RouteName from "@/router/name";
import {
  INVITE_MEMBER,
  GROUP_MEMBERS,
  REMOVE_MEMBER,
  UPDATE_MEMBER,
  APPROVE_MEMBER,
} from "@/graphql/member";
import { usernameWithDomain, displayName, IGroup } from "@/types/actor";
import EmptyContent from "@/components/Utils/EmptyContent.vue";
import { useHead } from "@vueuse/head";
import { useI18n } from "vue-i18n";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { computed, inject, ref } from "vue";
import {
  enumTransformer,
  integerTransformer,
  useRouteQuery,
} from "vue-use-route-query";
import {
  useCurrentActorClient,
  usePersonStatusGroup,
} from "@/composition/apollo/actor";
import { formatTimeString, formatDateString } from "@/filters/datetime";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import { Notifier } from "@/plugins/notifier";
import Tag from "@/components/TagElement.vue";

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Group members")),
});

const props = defineProps<{ preferredUsername: string }>();

const emit = defineEmits(["sort"]);

const { currentActor } = useCurrentActorClient();

const newMemberUsername = ref("");
const inviteError = ref("");
const page = useRouteQuery("page", 1, integerTransformer);
const roles = useRouteQuery("roles", undefined, enumTransformer(MemberRole));
const MEMBERS_PER_PAGE = 10;
const notifier = inject<Notifier>("notifier");

const {
  result: groupMembersResult,
  fetchMore: fetchMoreGroupMembers,
  loading: groupMembersLoading,
} = useQuery<{ group: IGroup }>(GROUP_MEMBERS, () => ({
  groupName: props.preferredUsername,
  page: page.value,
  limit: MEMBERS_PER_PAGE,
  roles: roles.value,
}));
const group = computed(() => groupMembersResult.value?.group);

const members = computed(
  () => group.value?.members ?? { total: 0, elements: [] }
);

const {
  mutate: inviteMemberMutation,
  onDone: onInviteMemberDone,
  onError: onInviteMemberError,
} = useMutation<{ inviteMember: IMember }>(INVITE_MEMBER, () => ({
  refetchQueries: [
    {
      query: GROUP_MEMBERS,
      variables: {
        groupName: props.preferredUsername,
        page: page.value,
        limit: MEMBERS_PER_PAGE,
        roles: roles.value,
      },
    },
  ],
}));

onInviteMemberError((error) => {
  console.error(error);
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    inviteError.value = error.graphQLErrors[0].message;
  }
});

onInviteMemberDone(() => {
  notifier?.success(
    t("{username} was invited to {group}", {
      username: newMemberUsername.value,
      group: displayName(group.value),
    })
  );
  newMemberUsername.value = "";
});

const inviteMember = async (): Promise<void> => {
  inviteError.value = "";
  inviteMemberMutation({
    groupId: group.value?.id,
    targetActorUsername: newMemberUsername.value,
  });
};

const loadMoreMembers = async (): Promise<void> => {
  await fetchMoreGroupMembers({
    // New variables
    variables() {
      return {
        name: usernameWithDomain(group.value),
        page,
        limit: MEMBERS_PER_PAGE,
        roles,
      };
    },
  });
};

const {
  mutate: mutateRemoveMember,
  onDone: onRemoveMemberDone,
  onError: onRemoveMemberError,
} = useMutation(REMOVE_MEMBER, () => ({
  refetchQueries: [
    {
      query: GROUP_MEMBERS,
      variables: {
        groupName: props.preferredUsername,
        page: page.value,
        limit: MEMBERS_PER_PAGE,
        roles: roles.value,
      },
    },
  ],
}));

onRemoveMemberDone(({ context }) => {
  let message = t("The member was removed from the group {group}", {
    group: displayName(group.value),
  }) as string;
  if (context?.oldMember.role === MemberRole.NOT_APPROVED) {
    message = t("The membership request from {profile} was rejected", {
      group: displayName(context?.oldMember.actor),
    }) as string;
  }
  notifier?.success(message);
});

onRemoveMemberError((error) => {
  console.error(error);
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    notifier?.error(error.graphQLErrors[0].message);
  }
});

const removeMember = (oldMember: IMember) => {
  mutateRemoveMember(
    {
      groupId: group.value?.id,
      memberId: oldMember.id,
    },
    {
      context: { oldMember },
    }
  );
};

const promoteMember = (member: IMember): void => {
  if (!member.id) return;
  if (member.role === MemberRole.MODERATOR) {
    updateMember(member, MemberRole.ADMINISTRATOR);
  }
  if (member.role === MemberRole.MEMBER) {
    updateMember(member, MemberRole.MODERATOR);
  }
};

const demoteMember = (member: IMember): void => {
  if (!member.id) return;
  if (member.role === MemberRole.MODERATOR) {
    updateMember(member, MemberRole.MEMBER);
  }
  if (member.role === MemberRole.ADMINISTRATOR) {
    updateMember(member, MemberRole.MODERATOR);
  }
};

const {
  mutate: approveMember,
  onDone: onApproveMemberDone,
  onError: onApproveMemberError,
} = useMutation<{ approveMember: IMember }, { memberId: string }>(
  APPROVE_MEMBER,
  {
    refetchQueries: [
      {
        query: GROUP_MEMBERS,
        variables: {
          groupName: props.preferredUsername,
          page: page.value,
          limit: MEMBERS_PER_PAGE,
          roles: roles.value,
        },
      },
    ],
  }
);

onApproveMemberDone(() => {
  notifier?.success(t("The member was approved"));
});

onApproveMemberError((error) => {
  console.error(error);
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    notifier?.error(error.graphQLErrors[0].message);
  }
});

const rejectMember = (member: IMember): void => {
  if (!member.id) return;
  removeMember(member);
};

const {
  mutate: updateMemberMutation,
  onDone: onUpdateMutationDone,
  onError: onUpdateMutationError,
} = useMutation<
  { id: string; role: MemberRole },
  { memberId: string; role: MemberRole; oldRole: MemberRole }
>(UPDATE_MEMBER, () => ({
  refetchQueries: [
    {
      query: GROUP_MEMBERS,
      variables: {
        groupName: props.preferredUsername,
        page: page.value,
        limit: MEMBERS_PER_PAGE,
        roles: roles.value,
      },
    },
  ],
}));

onUpdateMutationDone(({ data, context }) => {
  let successMessage;
  console.debug("onUpdateMutationDone", context);
  switch (data?.role) {
    case MemberRole.MODERATOR:
      successMessage = "The member role was updated to moderator";
      break;
    case MemberRole.ADMINISTRATOR:
      successMessage = "The member role was updated to administrator";
      break;
    case MemberRole.MEMBER:
      if (context?.oldMember.role === MemberRole.NOT_APPROVED) {
        successMessage = "The member was approved";
      } else {
        successMessage = "The member role was updated to simple member";
      }
      break;
    default:
      successMessage = "The member role was updated";
  }
  notifier?.success(t(successMessage));
});

onUpdateMutationError((error) => {
  console.error(error);
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    notifier?.error(error.graphQLErrors[0].message);
  }
});

const updateMember = async (
  oldMember: IMember,
  role: MemberRole
): Promise<void> => {
  updateMemberMutation(
    {
      memberId: oldMember.id as string,
      role,
      oldRole: oldMember.role,
    },
    { context: { oldMember } }
  );
};

const isCurrentActorAGroupAdmin = computed((): boolean => {
  return hasCurrentActorThisRole(MemberRole.ADMINISTRATOR);
});

const hasCurrentActorThisRole = (givenRole: string | string[]): boolean => {
  const rolesToConsider = Array.isArray(givenRole) ? givenRole : [givenRole];
  return (
    personMemberships.value?.total > 0 &&
    rolesToConsider.includes(personMemberships.value?.elements[0].role)
  );
};

const personMemberships = computed(
  () => person.value?.memberships ?? { total: 0, elements: [] }
);

const { person } = usePersonStatusGroup(props.preferredUsername);
</script>
