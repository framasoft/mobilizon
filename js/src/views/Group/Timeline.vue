<template>
  <div class="container section">
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul v-if="group">
        <li>
          <router-link
            :to="{
              name: RouteName.GROUP,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ group.name }}</router-link
          >
        </li>
        <li>
          <router-link
            :to="{
              name: RouteName.TIMELINE,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ $t("Activity") }}</router-link
          >
        </li>
      </ul>
    </nav>
    <section class="timeline">
      <transition-group name="timeline-list" tag="div">
        <div
          class="day"
          v-for="[date, activityItems] in Object.entries(activities)"
          :key="date"
        >
          <b-skeleton
            v-if="date.search(/skeleton/) !== -1"
            width="300px"
            height="48px"
          />
          <h2 class="is-size-3 has-text-weight-bold" v-else-if="isToday(date)">
            <span v-tooltip="$options.filters.formatDateString(date)">
              {{ $t("Today") }}
            </span>
          </h2>
          <h2
            class="is-size-3 has-text-weight-bold"
            v-else-if="isYesterday(date)"
          >
            <span v-tooltip="$options.filters.formatDateString(date)">{{
              $t("Yesterday")
            }}</span>
          </h2>
          <h2 v-else class="is-size-3 has-text-weight-bold">
            {{ date | formatDateString }}
          </h2>
          <ul>
            <li v-for="activityItem in activityItems" :key="activityItem.id">
              <skeleton-activity-item v-if="activityItem.skeleton" />
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
          !$apollo.loading &&
          activity.elements.length > 0 &&
          activity.elements.length >= activity.total
        "
      >
        {{ $t("No more activity to display.") }}
      </empty-content>
      <empty-content
        v-if="!$apollo.loading && activity.total === 0"
        icon="timeline-text"
      >
        {{
          $t(
            "There is no activity yet. Start doing some things to see activity appear here."
          )
        }}
      </empty-content>
      <observer @intersect="loadMore" />
      <b-button
        v-if="activity.elements.length < activity.total"
        @click="loadMore"
        >{{ $t("Load more activities") }}</b-button
      >
    </section>
  </div>
</template>
<script lang="ts">
import { GROUP_TIMELINE } from "@/graphql/group";
import { IGroup, usernameWithDomain } from "@/types/actor";
import { ActivityType } from "@/types/enums";
import { Paginate } from "@/types/paginate";
import { Component, Prop, Vue } from "vue-property-decorator";
import { IActivity } from "../../types/activity.model";
import Observer from "../../components/Utils/Observer.vue";
import SkeletonActivityItem from "../../components/Activity/SkeletonActivityItem.vue";
import RouteName from "../../router/name";

const PAGINATION_LIMIT = 25;
const SKELETON_DAY_ITEMS = 2;
const SKELETON_ITEMS_PER_DAY = 5;
type IActivitySkeleton = IActivity | { skeleton: string };

@Component({
  apollo: {
    group: {
      query: GROUP_TIMELINE,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          preferredUsername: this.preferredUsername,
          page: 1,
          limit: PAGINATION_LIMIT,
        };
      },
    },
  },
  components: {
    Observer,
    SkeletonActivityItem,
    "event-activity-item": () =>
      import("../../components/Activity/EventActivityItem.vue"),
    "post-activity-item": () =>
      import("../../components/Activity/PostActivityItem.vue"),
    "member-activity-item": () =>
      import("../../components/Activity/MemberActivityItem.vue"),
    "resource-activity-item": () =>
      import("../../components/Activity/ResourceActivityItem.vue"),
    "discussion-activity-item": () =>
      import("../../components/Activity/DiscussionActivityItem.vue"),
    "group-activity-item": () =>
      import("../../components/Activity/GroupActivityItem.vue"),
    "empty-content": () => import("../../components/Utils/EmptyContent.vue"),
  },
  metaInfo() {
    return {
      title: this.$t("{group} activity timeline", {
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        group: this.group?.name,
      }) as string,
      titleTemplate: "%s | Mobilizon",
    };
  },
})
export default class Timeline extends Vue {
  @Prop({ required: true, type: String }) preferredUsername!: string;

  group!: IGroup;

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;

  get activity(): Paginate<IActivitySkeleton> {
    if (this.group) {
      return this.group.activity;
    }
    return {
      total: 0,
      elements: this.skeletons.map((skeleton) => ({
        skeleton,
      })),
    };
  }

  page = 1;
  limit = PAGINATION_LIMIT;

  component(type: ActivityType): string | undefined {
    switch (type) {
      case ActivityType.EVENT:
        return "event-activity-item";
      case ActivityType.POST:
        return "post-activity-item";
      case ActivityType.MEMBER:
        return "member-activity-item";
      case ActivityType.RESOURCE:
        return "resource-activity-item";
      case ActivityType.DISCUSSION:
        return "discussion-activity-item";
      case ActivityType.GROUP:
        return "group-activity-item";
    }
  }

  get skeletons(): string[] {
    return [...Array(SKELETON_DAY_ITEMS)]
      .map((_, i) => {
        return [...Array(SKELETON_ITEMS_PER_DAY)].map((_a, j) => {
          return `${i}-${j}`;
        });
      })
      .flat();
  }

  async loadMore(): Promise<void> {
    if (this.page * PAGINATION_LIMIT >= this.activity.total) {
      return;
    }
    this.page++;
    try {
      await this.$apollo.queries.group.fetchMore({
        variables: {
          page: this.page,
          limit: PAGINATION_LIMIT,
        },
        updateQuery: (previousResult, { fetchMoreResult }) => {
          if (!fetchMoreResult) return previousResult;
          const newActivities = fetchMoreResult.group.activity.elements;
          const newTotal = fetchMoreResult.group.activity.total;
          return {
            group: {
              ...previousResult.group,
              activity: {
                __typename: previousResult.group.activity.__typename,
                total: newTotal,
                elements: [
                  ...previousResult.group.activity.elements,
                  ...newActivities,
                ],
              },
            },
          };
        },
      });
    } catch (e) {
      console.error(e);
    }
  }

  get activities(): Record<string, IActivitySkeleton[]> {
    return this.activity.elements.reduce(
      (acc: Record<string, IActivitySkeleton[]>, elem) => {
        let key;
        if (this.isIActivity(elem)) {
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
  }

  isIActivity(object: IActivitySkeleton): object is IActivity {
    return !("skeleton" in object);
  }

  getRandomInt(min: number, max: number): number {
    min = Math.ceil(min);
    max = Math.floor(max);
    return Math.floor(Math.random() * (max - min) + min);
  }

  isToday(dateString: string): boolean {
    const now = new Date();
    const date = new Date(dateString);
    return (
      now.getFullYear() === date.getFullYear() &&
      now.getMonth() === date.getMonth() &&
      now.getDate() === date.getDate()
    );
  }

  isYesterday(dateString: string): boolean {
    const date = new Date(dateString);
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    return (
      yesterday.getFullYear() === date.getFullYear() &&
      yesterday.getMonth() === date.getMonth() &&
      yesterday.getDate() === date.getDate()
    );
  }
}
</script>
<style lang="scss" scoped>
.container.section {
  background: $white;
}

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
