<template>
  <div class="container mx-auto section" v-if="group">
    <breadcrumbs-nav
      :links="[
        {
          name: RouteName.GROUP,
          params: { preferredUsername: usernameWithDomain(group) },
          text: displayName(group),
        },
        {
          name: RouteName.POSTS,
          params: { preferredUsername: usernameWithDomain(group) },
          text: $t('Posts'),
        },
      ]"
    />
    <section>
      <div class="intro">
        <p v-if="isCurrentActorMember">
          {{
            $t(
              "A place to publish something to the whole world, your community or just your group members."
            )
          }}
        </p>
        <p v-if="isCurrentActorMember">
          {{ $t("Only group moderators can create, edit and delete posts.") }}
        </p>
        <o-button
          tag="router-link"
          v-if="isCurrentActorAGroupModerator"
          :to="{
            name: RouteName.POST_CREATE,
            params: { preferredUsername: usernameWithDomain(group) },
          }"
          variant="primary"
          class="my-2"
          >{{ $t("+ Create a post") }}</o-button
        >
      </div>
      <div class="post-list">
        <multi-post-list-item
          :posts="group.posts.elements"
          :isCurrentActorMember="isCurrentActorMember"
        />
      </div>
      <o-loading v-model:active="loading"></o-loading>
      <o-notification
        v-if="
          group.posts.elements.length === 0 &&
          membershipsLoading === false &&
          groupLoading === false
        "
        variant="danger"
      >
        {{ $t("No posts found") }}
      </o-notification>
      <o-pagination
        :total="group.posts.total"
        v-model:current="postsPage"
        :per-page="POSTS_PAGE_LIMIT"
        :aria-next-label="$t('Next page')"
        :aria-previous-label="$t('Previous page')"
        :aria-page-label="$t('Page')"
        :aria-current-label="$t('Current page')"
      >
      </o-pagination>
    </section>
  </div>
</template>

<script lang="ts" setup>
import { PERSON_MEMBERSHIPS } from "@/graphql/actor";
import { FETCH_GROUP_POSTS } from "../../graphql/post";
import {
  usernameWithDomain,
  displayName,
  IPerson,
  IGroup,
} from "../../types/actor";
import RouteName from "../../router/name";
import MultiPostListItem from "../../components/Post/MultiPostListItem.vue";
import { useCurrentActorClient } from "@/composition/apollo/actor";
import { useQuery } from "@vue/apollo-composable";
import { computed } from "vue";
import { useHead } from "@unhead/vue";
import { integerTransformer, useRouteQuery } from "vue-use-route-query";
import { useI18n } from "vue-i18n";
import { MemberRole } from "@/types/enums";

const props = defineProps<{ preferredUsername: string }>();

const postsPage = useRouteQuery("page", 1, integerTransformer);
const POSTS_PAGE_LIMIT = 10;

const { currentActor } = useCurrentActorClient();

const { result: membershipsResult, loading: membershipsLoading } = useQuery<{
  person: Pick<IPerson, "memberships">;
}>(
  PERSON_MEMBERSHIPS,
  () => ({ id: currentActor.value?.id }),
  () => ({ enabled: currentActor.value?.id !== undefined })
);
const memberships = computed(() => membershipsResult.value?.person.memberships);

const { result: groupPostsResult, loading: groupLoading } = useQuery<{
  group: IGroup;
}>(
  FETCH_GROUP_POSTS,
  () => ({
    preferredUsername: props.preferredUsername,
    page: postsPage.value,
    limit: POSTS_PAGE_LIMIT,
  }),
  () => ({ enabled: props.preferredUsername !== undefined })
);

const group = computed(() => groupPostsResult.value?.group);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() =>
    t("{group} posts", {
      group: displayName(group.value),
    })
  ),
});

const loading = computed(() => membershipsLoading.value || groupLoading.value);

const isCurrentActorMember = computed((): boolean => {
  if (!group.value || !memberships.value) return false;
  return memberships.value.elements
    .map(({ parent: { id } }) => id)
    .includes(group.value.id);
});

const isCurrentActorAGroupModerator = computed((): boolean => {
  return hasCurrentActorThisRole([
    MemberRole.MODERATOR,
    MemberRole.ADMINISTRATOR,
  ]);
});

const hasCurrentActorThisRole = (givenRole: string | string[]): boolean => {
  const roles = Array.isArray(givenRole) ? givenRole : [givenRole];
  return (
    memberships.value !== undefined &&
    memberships.value?.total > 0 &&
    roles.includes(memberships.value?.elements[0].role)
  );
};
</script>
