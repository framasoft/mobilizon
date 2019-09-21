<template>
  <section>
    <h1>
      {{ $t('Group List') }}
    </h1>
    <b-loading :active.sync="$apollo.loading"></b-loading>
    <div class="columns">
      <GroupCard
        v-for="group in groups"
        :key="group.uuid"
        :group="group"
        class="column is-one-quarter-desktop is-half-mobile"
      />
    </div>
    <router-link class="button" :to="{ name: RouteName.CREATE_GROUP }">
      {{ $t('Create group') }}
    </router-link>
  </section>
</template>

<script lang="ts">
import { Component, Vue } from 'vue-property-decorator';
import { RouteName } from '@/router';

@Component
export default class GroupList extends Vue {
  groups = [];
  loading = true;

  RouteName = RouteName;

  created() {
    this.fetchData();
  }

  usernameWithDomain(actor) {
    return actor.username + (actor.domain === null ? '' : `@${actor.domain}`);
  }

  fetchData() {
    // FIXME: remove eventFetch
    // eventFetch('/groups', this.$store)
    //   .then(response => response.json())
    //   .then((data) => {
    //     console.log(data);
    //     this.loading = false;
    //     this.groups = data.data;
    //   });
  }

  deleteGroup(group) {
    const router = this.$router;
    // FIXME: remove eventFetch
    // eventFetch(`/groups/${this.usernameWithDomain(group)}`, this.$store, { method: 'DELETE' })
    //   .then(response => response.json())
    //   .then(() => router.push('/groups'));
  }

  viewActor(actor) {
    this.$router.push({
      name: RouteName.GROUP,
      params: { name: this.usernameWithDomain(actor) },
    });
  }

  joinGroup(group) {
    const router = this.$router;
    // FIXME: remove eventFetch
    // eventFetch(`/groups/${this.usernameWithDomain(group)}/join`, this.$store, { method: 'POST' })
    //   .then(response => response.json())
    //   .then(() => router.push({ name: 'Group', params: { name: this.usernameWithDomain(group) } }));
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
</style>
