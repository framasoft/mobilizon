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
            >{{ group.preferredUsername }}</router-link
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
      <p>
        {{
          $t(
            "When someone from the group creates an event and attributes it to the group, it will show up here."
          )
        }}
      </p>
      <b-loading :active.sync="$apollo.loading"></b-loading>
      <section v-if="group && group.organizedEvents.total > 0">
        <subtitle>
          {{ $t("Past events") }}
        </subtitle>
        <transition-group name="list" tag="p">
          <EventListViewCard v-for="event in group.organizedEvents.elements" :key="event.id" />
        </transition-group>
      </section>
      <b-message
        v-if="group.organizedEvents.elements.length === 0 && $apollo.loading === false"
        type="is-danger"
      >
        {{ $t("No events found") }}
      </b-message>
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { FETCH_GROUP } from "@/graphql/group";
import RouteName from "@/router/name";
import { IGroup, usernameWithDomain } from "../../types/actor";

@Component({
  apollo: {
    group: {
      query: FETCH_GROUP,
      variables() {
        return {
          name: this.$route.params.preferredUsername,
        };
      },
    },
  },
})
export default class GroupEvents extends Vue {
  group!: IGroup;

  usernameWithDomain = usernameWithDomain;

  RouteName = RouteName;
}
</script>
