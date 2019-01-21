<template>
  <section>
    <div class="columns">
      <div class="column">
        <div class="card" v-if="person">
          <div class="card-image" v-if="person.bannerUrl">
            <figure class="image">
              <img :src="person.bannerUrl">
            </figure>
          </div>
          <div class="card-content">
            <div class="media">
              <div class="media-left">
                <figure class="image is-48x48">
                  <img :src="person.avatarUrl">
                </figure>
              </div>
              <div class="media-content">
                <p class="title">{{ person.name }}</p>
                <p class="subtitle">@{{ person.preferredUsername }}</p>
              </div>
            </div>

            <div class="content">
              <p v-html="person.summary"></p>
            </div>
          </div>
          <section v-if="person.organizedEvents.length > 0">
            <h2 class="subtitle">
              <translate>Organized</translate>
            </h2>
            <div class="columns">
              <EventCard
                v-for="event in person.organizedEvents"
                :event="event"
                :hideDetails="true"
                :key="event.uuid"
                class="column is-one-third"
              />
            </div>
            <div class="field is-grouped">
              <p class="control">
                <a
                  class="button"
                  @click="logoutUser()"
                  v-if="loggedPerson && loggedPerson.id === person.id"
                >
                  <translate>User logout</translate>
                </a>
              </p>
              <p class="control">
                <a
                  class="button"
                  @click="deleteProfile()"
                  v-if="loggedPerson && loggedPerson.id === person.id"
                >
                  <translate>Delete</translate>
                </a>
              </p>
            </div>
          </section>
        </div>
      </div>
    </div>
  </section>
</template>

<script lang="ts">
import { FETCH_PERSON, LOGGED_PERSON } from "@/graphql/actor";
import { Component, Prop, Vue, Watch } from "vue-property-decorator";
import EventCard from "@/components/Event/EventCard.vue";

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
export default class Profile extends Vue {
  @Prop({ type: String, required: true }) name!: string;

  person = null;

  // call again the method if the route changes
  @Watch("$route")
  onRouteChange() {
    // this.fetchData()
  }

  logoutUser() {
    // TODO : implement logout
    this.$router.push({ name: "Home" });
  }

  nl2br(text) {
    return text.replace(/(?:\r\n|\r|\n)/g, "<br>");
  }
}
</script>
