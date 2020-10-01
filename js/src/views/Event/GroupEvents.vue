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
        {{ $t("{group}'s events", { group: group.name || group.preferredUsername }) }}
      </h1>
      <p v-if="isCurrentActorMember">
        {{
          $t(
            "When someone from the group creates an event and attributes it to the group, it will show up here."
          )
        }}
      </p>
      <b-loading :active.sync="$apollo.loading"></b-loading>
      <section v-if="group">
        <subtitle>
          {{ showPassedEvents ? $t("Past events") : $t("Upcoming events") }}
        </subtitle>
        <b-switch v-model="showPassedEvents">{{ $t("Past events") }}</b-switch>
        <transition-group name="list" tag="p">
          <EventListViewCard
            v-for="event in group.organizedEvents.elements"
            :key="event.id"
            :event="event"
            :options="{ memberofGroup: isCurrentActorMember }"
          />
        </transition-group>
        <b-message
          v-if="group.organizedEvents.elements.length === 0 && $apollo.loading === false"
          type="is-danger"
        >
          {{ $t("No events found") }}
        </b-message>
      </section>
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { FETCH_GROUP } from "@/graphql/group";
import RouteName from "@/router/name";
import Subtitle from "@/components/Utils/Subtitle.vue";
import EventListViewCard from "@/components/Event/EventListViewCard.vue";
import { CURRENT_ACTOR_CLIENT, PERSON_MEMBERSHIPS } from "@/graphql/actor";
import { IGroup, IMember, IPerson, usernameWithDomain } from "../../types/actor";

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
      query: FETCH_GROUP,
      variables() {
        return {
          name: this.$route.params.preferredUsername,
          beforeDateTime: this.showPassedEvents ? new Date() : null,
          afterDateTime: this.showPassedEvents ? null : new Date(),
        };
      },
    },
  },
  components: {
    Subtitle,
    EventListViewCard,
  },
})
export default class GroupEvents extends Vue {
  group!: IGroup;

  memberships!: IMember[];

  currentActor!: IPerson;

  usernameWithDomain = usernameWithDomain;

  RouteName = RouteName;

  showPassedEvents = false;

  get isCurrentActorMember(): boolean {
    if (!this.group || !this.memberships) return false;
    return this.memberships.map(({ parent: { id } }) => id).includes(this.group.id);
  }
}
</script>
