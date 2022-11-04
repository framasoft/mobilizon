<template>
  <div class="container mx-auto section" v-if="group">
    <breadcrumbs-nav
      :links="[
        {
          name: RouteName.MY_GROUPS,
          text: t('My groups'),
        },
        {
          name: RouteName.GROUP,
          params: { preferredUsername: usernameWithDomain(group) },
          text: displayName(group),
        },
        {
          name: RouteName.DISCUSSION_LIST,
          params: { preferredUsername: usernameWithDomain(group) },
          text: t('Discussions'),
        },
      ]"
    />
    <section v-if="isCurrentActorAGroupMember">
      <h1>{{ t("Discussions") }}</h1>
      <p>
        {{
          t(
            "Keep the entire conversation about a specific topic together on a single page."
          )
        }}
      </p>
      <o-button
        tag="router-link"
        :to="{
          name: RouteName.CREATE_DISCUSSION,
          params: { preferredUsername },
        }"
        >{{ t("New discussion") }}</o-button
      >
      <div v-if="group.discussions.elements.length > 0">
        <discussion-list-item
          :discussion="discussion"
          v-for="discussion in group.discussions.elements"
          :key="discussion.id"
        />
        <o-pagination
          v-show="group.discussions.total > DISCUSSIONS_PER_PAGE"
          class="discussion-pagination"
          :total="group.discussions.total"
          v-model="page"
          :per-page="DISCUSSIONS_PER_PAGE"
          :aria-next-label="t('Next page')"
          :aria-previous-label="t('Previous page')"
          :aria-page-label="t('Page')"
          :aria-current-label="t('Current page')"
        >
        </o-pagination>
      </div>
      <empty-content v-else icon="chat">
        {{ t("There's no discussions yet") }}
      </empty-content>
    </section>
    <section class="section" v-else-if="!groupLoading && !personLoading">
      <empty-content icon="chat">
        {{ t("Only group members can access discussions") }}
        <template #desc>
          <router-link
            :to="{ name: RouteName.GROUP, params: { preferredUsername } }"
          >
            {{ t("Return to the group page") }}
          </router-link>
        </template>
      </empty-content>
    </section>
  </div>
</template>
<script lang="ts" setup>
import { displayName, usernameWithDomain } from "@/types/actor";
import DiscussionListItem from "@/components/Discussion/DiscussionListItem.vue";
import RouteName from "../../router/name";
import { MemberRole } from "@/types/enums";

import { IMember } from "@/types/actor/member.model";
import EmptyContent from "@/components/Utils/EmptyContent.vue";
import { useGroup } from "@/composition/apollo/group";
import { usePersonStatusGroup } from "@/composition/apollo/actor";
import { useI18n } from "vue-i18n";
import { useRouteQuery, integerTransformer } from "vue-use-route-query";
import { useHead } from "@vueuse/head";
import { computed } from "vue";

const page = useRouteQuery("page", 1, integerTransformer);
const DISCUSSIONS_PER_PAGE = 10;

const props = defineProps<{ preferredUsername: string }>();

const { group, loading: groupLoading } = useGroup(props.preferredUsername, {
  discussionsPage: page.value,
  discussionsLimit: DISCUSSIONS_PER_PAGE,
});

const { person, loading: personLoading } = usePersonStatusGroup(
  props.preferredUsername
);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Discussions")),
});

const groupMemberships = computed((): (string | undefined)[] => {
  if (!person.value || !person.value.id) return [];
  return person.value.memberships.elements
    .filter(
      (membership: IMember) =>
        ![
          MemberRole.REJECTED,
          MemberRole.NOT_APPROVED,
          MemberRole.INVITED,
        ].includes(membership.role)
    )
    .map(({ parent: { id } }) => id);
});

const isCurrentActorAGroupMember = computed((): boolean => {
  return (
    groupMemberships.value !== undefined &&
    groupMemberships.value.includes(group.value?.id)
  );
});
</script>
