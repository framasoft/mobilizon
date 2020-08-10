<template>
  <section class="container section">
    <h1>{{ $t("Group List") }} ({{ groups.total }})</h1>
    <b-loading :active.sync="$apollo.loading" />
    <div class="columns">
      <GroupMemberCard
        v-for="group in groups.elements"
        :key="group.uuid"
        :group="group"
        class="column is-one-quarter-desktop is-half-mobile"
      />
    </div>
    <router-link class="button" :to="{ name: RouteName.CREATE_GROUP }">{{
      $t("Create group")
    }}</router-link>
  </section>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { LIST_GROUPS } from "@/graphql/actor";
import { Group, IGroup } from "@/types/actor";
import GroupMemberCard from "@/components/Group/GroupMemberCard.vue";
import RouteName from "../../router/name";

@Component({
  apollo: {
    groups: {
      query: LIST_GROUPS,
    },
  },
  components: {
    GroupMemberCard,
  },
})
export default class GroupList extends Vue {
  groups: { elements: IGroup[]; total: number } = { elements: [], total: 0 };

  loading = true;

  RouteName = RouteName;
  //
  // usernameWithDomain(actor) {
  //   return actor.username + (actor.domain === null ? '' : `@${actor.domain}`);
  // }

  // viewActor(actor) {
  //   this.$router.push({
  //     name: RouteName.GROUP,
  //     params: { name: this.usernameWithDomain(actor) },
  //   });
  // }
  //
  // joinGroup(group) {
  //   const router = this.$router;
  //   // FIXME: remove eventFetch
  //   // eventFetch(`/groups/${this.usernameWithDomain(group)}/join`, this.$store, { method: 'POST' })
  //   //   .then(response => response.json())
  //   //   .then(() => router.push({ name: 'Group', params: { name: this.usernameWithDomain(group) } }));
  // }
}
</script>
