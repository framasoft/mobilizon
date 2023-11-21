<template>
  <div class="container mx-auto section">
    <breadcrumbs-nav
      v-if="group"
      :links="[
        {
          name: RouteName.GROUP,
          params: { preferredUsername: usernameWithDomain(group) },
          text: displayName(group),
        },
        {
          name: RouteName.TIMELINE,
          params: { preferredUsername: usernameWithDomain(group) },
          text: t('Activity'),
        },
      ]"
    />

    <section class="timeline">
      <o-field>
        <o-radio class="pr-4" v-model="activityType" :native-value="undefined">
          <TimelineText />
          {{ t("All activities") }}</o-radio
        >
        <o-radio
          class="pr-4"
          v-model="activityType"
          :native-value="ActivityType.MEMBER"
        >
          <o-icon icon="account-multiple-plus"></o-icon>
          {{ t("Members") }}</o-radio
        >
        <o-radio
          class="pr-4"
          v-model="activityType"
          :native-value="ActivityType.GROUP"
        >
          <o-icon icon="cog"></o-icon>
          {{ t("Settings") }}</o-radio
        >
        <o-radio
          class="pr-4"
          v-model="activityType"
          :native-value="ActivityType.EVENT"
        >
          <o-icon icon="calendar"></o-icon>
          {{ t("Events") }}</o-radio
        >
        <o-radio
          class="pr-4"
          v-model="activityType"
          :native-value="ActivityType.POST"
        >
          <o-icon icon="bullhorn"></o-icon>
          {{ t("Posts") }}</o-radio
        >
        <o-radio
          class="pr-4"
          v-model="activityType"
          :native-value="ActivityType.DISCUSSION"
        >
          <o-icon icon="chat"></o-icon>
          {{ t("Discussions") }}</o-radio
        >
        <o-radio v-model="activityType" :native-value="ActivityType.RESOURCE">
          <o-icon icon="link"></o-icon>
          {{ t("Resources") }}</o-radio
        >
      </o-field>
      <o-field>
        <o-radio
          class="pr-4"
          v-model="activityAuthor"
          :native-value="undefined"
        >
          <TimelineText />
          {{ t("All activities") }}</o-radio
        >
        <o-radio
          class="pr-4"
          v-model="activityAuthor"
          :native-value="ActivityAuthorFilter.SELF"
        >
          <o-icon icon="account"></o-icon>
          {{ t("From yourself") }}</o-radio
        >
        <o-radio
          class="pr-4"
          v-model="activityAuthor"
          :native-value="ActivityAuthorFilter.BY"
        >
          <o-icon icon="account-multiple"></o-icon>
          {{ t("By others") }}</o-radio
        >
      </o-field>
      <transition-group name="timeline-list" tag="div">
        <div
          class="day"
          v-for="[date, activityItems] in Object.entries(activities)"
          :key="date"
        >
          <o-skeleton
            v-if="date.search(/skeleton/) !== -1"
            width="300px"
            height="48px"
          />
          <h2 v-else-if="isToday(date)">
            <span v-tooltip="formatDateString(date)">
              {{ t("Today") }}
            </span>
          </h2>
          <h2 v-else-if="isYesterday(date)">
            <span v-tooltip="formatDateString(date)">{{ t("Yesterday") }}</span>
          </h2>
          <h2 v-else>
            {{ formatDateString(date) }}
          </h2>
          <ul class="before:opacity-10">
            <li v-for="activityItem in activityItems" :key="activityItem.id">
              <skeleton-activity-item v-if="activityItem.type === 'skeleton'" />
              <component
                v-else
                :is="component(activityItem.type)"
                :activity="activityItem"
              />
            </li>
          </ul></div
      ></transition-group>
      <empty-content
        icon="timeline-text"
        v-if="
          !loading &&
          activity.elements.length > 0 &&
          activity.elements.length >= activity.total
        "
      >
        {{ t("No more activity to display.") }}
      </empty-content>
      <empty-content
        v-if="!loading && activity.total === 0"
        icon="timeline-text"
      >
        {{
          t(
            "There is no activity yet. Start doing some things to see activity appear here."
          )
        }}
      </empty-content>
      <observer @intersect="loadMore" />
      <o-button
        v-if="activity.elements.length < activity.total"
        @click="loadMore"
        >{{ t("Load more activities") }}</o-button
      >
    </section>
  </div>
</template>
<script lang="ts" setup>
import { GROUP_TIMELINE } from "@/graphql/group";
import { IGroup, usernameWithDomain, displayName } from "@/types/actor";
import { ActivityType } from "@/types/enums";
import { Paginate } from "@/types/paginate";
import { IActivity } from "../../types/activity.model";
import Observer from "../../components/Utils/ObserverElement.vue";
import SkeletonActivityItem from "../../components/Activity/SkeletonActivityItem.vue";
import RouteName from "../../router/name";
import TimelineText from "vue-material-design-icons/TimelineText.vue";
import { useQuery } from "@vue/apollo-composable";
import { useHead } from "@unhead/vue";
import { enumTransformer, useRouteQuery } from "vue-use-route-query";
import { computed, defineAsyncComponent, ref } from "vue";
import { useI18n } from "vue-i18n";
import { formatDateString } from "@/filters/datetime";

const PAGINATION_LIMIT = 25;
const SKELETON_DAY_ITEMS = 2;
const SKELETON_ITEMS_PER_DAY = 5;
type IActivitySkeleton =
  | IActivity
  | { skeleton: string; id: string; type: "skeleton" };

enum ActivityAuthorFilter {
  SELF = "SELF",
  BY = "BY",
}

// type ActivityFilter = ActivityType | ActivityAuthorFilter | null;

const props = defineProps<{ preferredUsername: string }>();

const { t } = useI18n({ useScope: "global" });

const EventActivityItem = defineAsyncComponent(
  () => import("../../components/Activity/EventActivityItem.vue")
);
const PostActivityItem = defineAsyncComponent(
  () => import("../../components/Activity/PostActivityItem.vue")
);
const MemberActivityItem = defineAsyncComponent(
  () => import("../../components/Activity/MemberActivityItem.vue")
);
const ResourceActivityItem = defineAsyncComponent(
  () => import("../../components/Activity/ResourceActivityItem.vue")
);
const DiscussionActivityItem = defineAsyncComponent(
  () => import("../../components/Activity/DiscussionActivityItem.vue")
);
const GroupActivityItem = defineAsyncComponent(
  () => import("../../components/Activity/GroupActivityItem.vue")
);
const EmptyContent = defineAsyncComponent(
  () => import("../../components/Utils/EmptyContent.vue")
);

const activityType = useRouteQuery(
  "activityType",
  undefined,
  enumTransformer(ActivityType)
);
const activityAuthor = useRouteQuery(
  "activityAuthor",
  undefined,
  enumTransformer(ActivityAuthorFilter)
);

const page = ref(1);

const {
  result: groupTimelineResult,
  fetchMore: fetchMoreActivities,
  onError: onGroupTLError,
  loading,
} = useQuery<{ group: IGroup }>(GROUP_TIMELINE, () => ({
  preferredUsername: props.preferredUsername,
  page: page.value,
  limit: PAGINATION_LIMIT,
  type: activityType.value,
  author: activityAuthor.value,
}));

onGroupTLError((err) => console.error(err));

const group = computed(() => groupTimelineResult.value?.group);

useHead({
  title: computed(() =>
    t("{group} activity timeline", { group: group.value?.name })
  ),
});

const activity = computed((): Paginate<IActivitySkeleton> => {
  if (group.value) {
    return group.value.activity;
  }
  return {
    total: 0,
    elements: skeletons.value.map((skeleton) => ({
      skeleton,
      id: skeleton,
      type: "skeleton",
    })),
  };
});

const component = (type: ActivityType): any | undefined => {
  switch (type) {
    case ActivityType.EVENT:
      return EventActivityItem;
    case ActivityType.POST:
      return PostActivityItem;
    case ActivityType.MEMBER:
      return MemberActivityItem;
    case ActivityType.RESOURCE:
      return ResourceActivityItem;
    case ActivityType.DISCUSSION:
      return DiscussionActivityItem;
    case ActivityType.GROUP:
      return GroupActivityItem;
  }
};

const skeletons = computed((): string[] => {
  return [...Array(SKELETON_DAY_ITEMS)]
    .map((_, i) => {
      return [...Array(SKELETON_ITEMS_PER_DAY)].map((_a, j) => {
        return `${i}-${j}`;
      });
    })
    .flat();
});

const loadMore = async (): Promise<void> => {
  if (page.value * PAGINATION_LIMIT >= activity.value.total) {
    return;
  }
  page.value++;
  try {
    await fetchMoreActivities({
      variables: {
        page: page.value,
        limit: PAGINATION_LIMIT,
      },
    });
  } catch (e) {
    console.error(e);
  }
};

const activities = computed((): Record<string, IActivitySkeleton[]> => {
  return activity.value.elements.reduce(
    (acc: Record<string, IActivitySkeleton[]>, elem) => {
      let key;
      if (isIActivity(elem)) {
        const insertedAt = new Date(elem.insertedAt);
        insertedAt.setHours(0);
        insertedAt.setMinutes(0);
        insertedAt.setSeconds(0);
        insertedAt.setMilliseconds(0);
        key = insertedAt.toISOString();
      } else {
        key = `skeleton-${elem.skeleton.split("-")[0]}`;
      }
      const existing = acc[key];
      if (existing) {
        acc[key] = [...existing, ...[elem]];
      } else {
        acc[key] = [elem];
      }
      return acc;
    },
    {}
  );
});

const isIActivity = (object: IActivitySkeleton): object is IActivity => {
  return !("skeleton" in object);
};
// const getRandomInt = (min: number, max: number): number => {
//   min = Math.ceil(min);
//   max = Math.floor(max);
//   return Math.floor(Math.random() * (max - min) + min);
// };

const isToday = (dateString: string): boolean => {
  const now = new Date();
  const date = new Date(dateString);
  return (
    now.getFullYear() === date.getFullYear() &&
    now.getMonth() === date.getMonth() &&
    now.getDate() === date.getDate()
  );
};

const isYesterday = (dateString: string): boolean => {
  const date = new Date(dateString);
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  return (
    yesterday.getFullYear() === date.getFullYear() &&
    yesterday.getMonth() === date.getMonth() &&
    yesterday.getDate() === date.getDate()
  );
};
</script>
<style lang="scss" scoped>
.timeline {
  ul {
    // padding: 0.5rem 0;
    margin: 0;
    list-style: none;
    position: relative;
    &::before {
      content: "";
      height: 100%;
      width: 1px;
      background-color: #d9d9d9;
      position: absolute;
      top: 0;
      left: 1rem;
    }
    li {
      display: flex;
      margin: 0.5rem 0;
    }
  }
}
</style>
