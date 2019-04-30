<template>
  <section class="container">
    <div v-if="group">
      <div class="card-image" v-if="group.bannerUrl">
        <figure class="image">
          <img :src="group.bannerUrl">
        </figure>
      </div>
      <div class="box">
        <div class="media">
          <div class="media-left">
            <figure class="image is-48x48">
              <img :src="group.avatarUrl">
            </figure>
          </div>
          <div class="media-content">
            <p class="title">{{ group.name }}</p>
            <p class="subtitle">@{{ group.preferredUsername }}</p>
          </div>
        </div>

        <div class="content">
          <p v-html="group.summary"></p>
        </div>
      </div>
      <section class="box" v-if="group.organizedEvents.length > 0">
        <h2 class="subtitle">
          <translate>Organized</translate>
        </h2>
        <div class="columns">
          <EventCard
            v-for="event in group.organizedEvents"
            :event="event"
            :options="{ hideDetails: true }"
            :key="event.uuid"
            class="column is-one-third"
          />
        </div>
      </section>
      <section v-if="group.members.length > 0">
        <h2 class="subtitle">
          <translate>Members</translate>
        </h2>
        <div class="columns">
          <span
            v-for="member in group.members"
            :key="member.actor.preferredUsername"
          >{{ member.actor.preferredUsername }}</span>
        </div>
      </section>
    </div>
    <b-message v-else-if="!group && $apollo.loading === false" type="is-danger">
      <translate>No group found</translate>
    </b-message>
  </section>
</template>

<script lang="ts">
import { Component, Prop, Vue, Watch } from 'vue-property-decorator';
import EventCard from '@/components/Event/EventCard.vue';
import { FETCH_GROUP, LOGGED_PERSON } from '@/graphql/actor';
import { IGroup } from '@/types/actor';

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
    loggedPerson: {
      query: LOGGED_PERSON,
    },
  },
  components: {
    EventCard,
  },
})
export default class Group extends Vue {
  @Prop({ type: String, required: true }) preferredUsername!: string;

  group!: IGroup;
  loading = true;

  created() {
    this.fetchData();
  }

  @Watch('$route')
  onRouteChanged() {
    // call again the method if the route changes
    this.fetchData();
  }

  fetchData() {
    // FIXME: remove eventFetch
    // eventFetch(`/actors/${this.name}`, this.$store)
    //   .then(response => response.json())
    //   .then((response) => {
    //     this.group = response.data;
    //     this.loading = false;
    //     console.log(this.group);
    //   });
  }
}
</script>
<style lang="scss">
  section.container {
    min-height: 30em;
  }
</style>
