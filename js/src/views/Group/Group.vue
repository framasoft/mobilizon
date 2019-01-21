<template>
  <section>
    <div class="columns">
      <div class="column">
        <div class="card" v-if="group">
          <div class="card-image" v-if="group.bannerUrl">
            <figure class="image">
              <img :src="group.bannerUrl">
            </figure>
          </div>
          <div class="card-content">
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
          <section v-if="group.organizedEvents.length > 0">
            <h2 class="subtitle">
              <translate>Organized</translate>
            </h2>
            <div class="columns">
              <EventCard
                v-for="event in group.organizedEvents"
                :event="event"
                :hideDetails="true"
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
                :key="member"
              >{{ member.actor.preferredUsername }}</span>
            </div>
          </section>
        </div>
        <b-message v-if-else="!group && $apollo.loading === false" type="is-danger">
          <translate>No group found</translate>
        </b-message>
      </div>
    </div>
  </section>
</template>

<script lang="ts">
import { Component, Prop, Vue, Watch } from "vue-property-decorator";
import EventCard from "@/components/Event/EventCard.vue";
import { FETCH_PERSON, LOGGED_PERSON } from "@/graphql/actor";

@Component({
  apollo: {
    person: {
      query: FETCH_PERSON,
      variables() {
        return {
          name: this.$route.params.name
        };
      }
    },
    loggedPerson: {
      query: LOGGED_PERSON
    }
  },
  components: {
    EventCard
  }
})
export default class Group extends Vue {
  @Prop({ type: String, required: true }) name!: string;

  group = null;
  loading = true;

  created() {
    this.fetchData();
  }

  @Watch("$route")
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
