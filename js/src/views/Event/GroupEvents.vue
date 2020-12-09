<template>
  <div class="container section" v-if="group">
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link
            :to="{
              name: RouteName.GROUP,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ group.name }}</router-link
          >
        </li>
        <li class="is-active">
          <router-link
            :to="{
              name: RouteName.TODO_LISTS,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ $t("Events") }}</router-link
          >
        </li>
      </ul>
    </nav>
    <section>
      <h1 class="title" v-if="group">
        {{
          $t("{group}'s events", {
            group: group.name || group.preferredUsername,
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
        }"
        class="button is-primary"
        >{{ $t("+ Create an event") }}</router-link
      >
      <b-loading :active.sync="$apollo.loading"></b-loading>
      <section v-if="group">
        <subtitle>
          {{ showPassedEvents ? $t("Past events") : $t("Upcoming events") }}
        </subtitle>
        <b-switch v-model="showPassedEvents">{{ $t("Past events") }}</b-switch>
        <transition-group name="list" tag="div" class="event-list">
          <EventListViewCard
            v-for="event in group.organizedEvents.elements"
            :key="event.id"
            :event="event"
            :options="{ memberofGroup: isCurrentActorMember }"
          />
        </transition-group>
        <b-message
          v-if="
            group.organizedEvents.elements.length === 0 &&
            $apollo.loading === false
          "
          type="is-danger"
        >
          {{ $t("No events found") }}
        </b-message>
        <b-pagination
          :total="group.organizedEvents.total"
          v-model="eventsPage"
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
import { Component } from "vue-property-decorator";
import { mixins } from "vue-class-component";
import RouteName from "@/router/name";
import Subtitle from "@/components/Utils/Subtitle.vue";
import EventListViewCard from "@/components/Event/EventListViewCard.vue";
import { CURRENT_ACTOR_CLIENT, PERSON_MEMBERSHIPS } from "@/graphql/actor";
import GroupMixin from "@/mixins/group";
import { IMember } from "@/types/actor/member.model";
import { FETCH_GROUP_EVENTS } from "@/graphql/event";
import { IGroup, IPerson, usernameWithDomain } from "../../types/actor";

const EVENTS_PAGE_LIMIT = 10;

@Component({
  apollo: {
    currentActor: CURRENT_ACTOR_CLIENT,
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
          organisedEventsPage: this.eventsPage,
          organisedEventslimit: EVENTS_PAGE_LIMIT,
        };
      },
    },
  },
  components: {
    Subtitle,
    EventListViewCard,
  },
})
export default class GroupEvents extends mixins(GroupMixin) {
  group!: IGroup;

  memberships!: IMember[];

  currentActor!: IPerson;

  eventsPage = 1;

  usernameWithDomain = usernameWithDomain;

  RouteName = RouteName;

  EVENTS_PAGE_LIMIT = EVENTS_PAGE_LIMIT;

  get isCurrentActorMember(): boolean {
    if (!this.group || !this.memberships) return false;
    return this.memberships
      .map(({ parent: { id } }) => id)
      .includes(this.group.id);
  }

  get showPassedEvents(): boolean {
    return (
      this.$route.query.future !== undefined &&
      this.$route.query.future.toString() === "false"
    );
  }

  set showPassedEvents(value: boolean) {
    this.$router.push({ query: { future: this.showPassedEvents.toString() } });
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
