<template>
  <div class="container section" v-if="group">
    <breadcrumbs-nav
      :links="[
        {
          name: RouteName.GROUP,
          params: { preferredUsername: usernameWithDomain(group) },
          text: displayName(group),
        },
        {
          name: RouteName.EVENTS,
          params: { preferredUsername: usernameWithDomain(group) },
          text: $t('Events'),
        },
      ]"
    />
    <section>
      <h1 class="title" v-if="group">
        {{
          $t("{group}'s events", {
            group: displayName(group),
          })
        }}
      </h1>
      <p v-if="isCurrentActorMember">
        {{
          $t(
            "When a moderator from the group creates an event and attributes it to the group, it will show up here."
          )
        }}
      </p>
      <router-link
        v-if="isCurrentActorAGroupModerator"
        :to="{
          name: RouteName.CREATE_EVENT,
          query: { actorId: group.id },
        }"
        class="button is-primary"
        >{{ $t("+ Create an event") }}</router-link
      >
      <b-loading :active.sync="$apollo.loading"></b-loading>
      <section v-if="group">
        <subtitle>
          {{ showPassedEvents ? $t("Past events") : $t("Upcoming events") }}
        </subtitle>
        <b-switch class="mb-4" v-model="showPassedEvents">{{
          $t("Past events")
        }}</b-switch>
        <grouped-multi-event-minimalist-card
          :events="group.organizedEvents.elements"
          :isCurrentActorMember="isCurrentActorMember"
        />
        <empty-content
          v-if="
            group.organizedEvents.elements.length === 0 &&
            $apollo.loading === false
          "
          icon="calendar"
          :inline="true"
          :center="true"
        >
          {{ $t("No events found") }}
          <template v-if="group.domain !== null">
            <div class="mt-4">
              <p>
                {{
                  $t(
                    "This group is a remote group, it's possible the original instance has more informations."
                  )
                }}
              </p>
              <b-button type="is-text" tag="a" :href="group.url">
                {{ $t("View the group profile on the original instance") }}
              </b-button>
            </div>
          </template>
        </empty-content>
        <b-pagination
          class="mt-4"
          :total="group.organizedEvents.total"
          v-model="page"
          :per-page="EVENTS_PAGE_LIMIT"
          :aria-next-label="$t('Next page')"
          :aria-previous-label="$t('Previous page')"
          :aria-page-label="$t('Page')"
          :aria-current-label="$t('Current page')"
        >
        </b-pagination>
      </section>
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import RouteName from "@/router/name";
import Subtitle from "@/components/Utils/Subtitle.vue";
import GroupedMultiEventMinimalistCard from "@/components/Event/GroupedMultiEventMinimalistCard.vue";
import { PERSON_MEMBERSHIPS } from "@/graphql/actor";
import { IMember } from "@/types/actor/member.model";
import { FETCH_GROUP_EVENTS } from "@/graphql/event";
import EmptyContent from "../../components/Utils/EmptyContent.vue";
import { displayName, IGroup, usernameWithDomain } from "../../types/actor";

const EVENTS_PAGE_LIMIT = 10;

@Component({
  apollo: {
    memberships: {
      query: PERSON_MEMBERSHIPS,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          id: this.currentActor.id,
        };
      },
      update: (data) => data.person.memberships.elements,
      skip() {
        return !this.currentActor || !this.currentActor.id;
      },
    },
    group: {
      query: FETCH_GROUP_EVENTS,
      variables() {
        return {
          name: this.$route.params.preferredUsername,
          beforeDateTime: this.showPassedEvents ? new Date() : null,
          afterDateTime: this.showPassedEvents ? null : new Date(),
          organisedEventsPage: this.page,
          organisedEventsLimit: EVENTS_PAGE_LIMIT,
        };
      },
      update: (data) => data.group,
    },
  },
  components: {
    EmptyContent,
    Subtitle,
    GroupedMultiEventMinimalistCard,
  },
  metaInfo() {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    const { group } = this;
    return {
      title: this.$t("{group} events", {
        group: displayName(group),
      }) as string,
    };
  },
})
export default class GroupEvents extends Vue {
  group!: IGroup;

  memberships!: IMember[];

  get page(): number {
    return parseInt((this.$route.query.page as string) || "1", 10);
  }

  set page(page: number) {
    this.$router.push({
      name: RouteName.GROUP_EVENTS,
      query: { ...this.$route.query, page: page.toString() },
    });
    this.$apollo.queries.group.refetch();
  }

  usernameWithDomain = usernameWithDomain;

  displayName = displayName;

  RouteName = RouteName;

  EVENTS_PAGE_LIMIT = EVENTS_PAGE_LIMIT;

  get isCurrentActorMember(): boolean {
    if (!this.group || !this.memberships) return false;
    return this.memberships
      .map(({ parent: { id } }) => id)
      .includes(this.group.id);
  }

  get showPassedEvents(): boolean {
    return this.$route.query.future === "false";
  }

  set showPassedEvents(value: boolean) {
    this.$router.replace({ query: { future: (!value).toString() } });
  }
}
</script>
<style lang="scss" scoped>
.container.section {
  background: $white;
}

div.event-list {
  margin-bottom: 1rem;
}
</style>
