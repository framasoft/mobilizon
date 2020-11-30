<template>
  <section class="container">
    <div v-if="person">
      <div class="card-image" v-if="person.banner">
        <figure class="image">
          <img :src="person.banner.url" />
        </figure>
      </div>
      <div class="card-content">
        <div class="media">
          <div class="media-left">
            <figure class="image is-48x48" v-if="person.avatar">
              <img :src="person.avatar.url" />
            </figure>
          </div>
          <div class="media-content">
            <p class="title">{{ person.name }}</p>
            <p class="subtitle">@{{ person.preferredUsername }}</p>
          </div>
        </div>
        <div class="content">
          <vue-simple-markdown :source="person.summary"></vue-simple-markdown>
        </div>

        <b-dropdown hoverable has-link aria-role="list">
          <button class="button is-primary" slot="trigger">
            {{ $t("Public feeds") }}
            <b-icon icon="menu-down"></b-icon>
          </button>

          <b-dropdown-item aria-role="listitem">
            <a :href="feedUrls('atom', true)">
              {{ $t("Public RSS/Atom Feed") }}
            </a>
          </b-dropdown-item>
          <b-dropdown-item aria-role="listitem">
            <a :href="feedUrls('ics', true)">
              {{ $t("Public iCal Feed") }}
            </a>
          </b-dropdown-item>
        </b-dropdown>

        <b-dropdown
          hoverable
          has-link
          aria-role="list"
          v-if="person.feedTokens.length > 0"
        >
          <button class="button is-info" slot="trigger">
            {{ $t("Private feeds") }}
            <b-icon icon="menu-down"></b-icon>
          </button>

          <b-dropdown-item aria-role="listitem">
            <a :href="feedUrls('atom', false)">
              {{ $t("RSS/Atom Feed") }}
            </a>
          </b-dropdown-item>
          <b-dropdown-item aria-role="listitem">
            <a :href="feedUrls('ics', false)">
              {{ $t("iCal Feed") }}
            </a>
          </b-dropdown-item>
        </b-dropdown>
        <a
          class="button"
          v-if="currentActor.id === person.id"
          @click="createToken"
        >
          {{ $t("Create token") }}
        </a>
      </div>
      <section v-if="person.organizedEvents.length > 0">
        <h2 class="subtitle">
          {{ $t("Organized") }}
        </h2>
        <div class="columns">
          <EventCard
            v-for="event in person.organizedEvents"
            :event="event"
            :options="{ hideDetails: true, organizerActor: person }"
            :key="event.uuid"
            class="column is-one-third"
          />
        </div>
        <div class="field is-grouped">
          <p class="control">
            <a
              class="button"
              @click="deleteProfile()"
              v-if="currentActor && currentActor.id === person.id"
            >
              {{ $t("Delete") }}
            </a>
          </p>
        </div>
      </section>
    </div>
  </section>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import EventCard from "@/components/Event/EventCard.vue";
import { FETCH_PERSON, CURRENT_ACTOR_CLIENT } from "../../graphql/actor";
import { MOBILIZON_INSTANCE_HOST } from "../../api/_entrypoint";
import { IPerson } from "../../types/actor";
import { CREATE_FEED_TOKEN_ACTOR } from "../../graphql/feed_tokens";

@Component({
  apollo: {
    person: {
      query: FETCH_PERSON,
      variables() {
        return {
          username: this.$route.params.name,
        };
      },
    },
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
  },
  components: {
    EventCard,
  },
})
export default class Profile extends Vue {
  @Prop({ type: String, required: true }) name!: string;

  person!: IPerson;

  currentActor!: IPerson;

  feedUrls(format: "ics" | "webcal:" | "atom", isPublic = true): string {
    let url = format === "ics" ? "webcal:" : "";
    url += `//${MOBILIZON_INSTANCE_HOST}/`;
    if (isPublic === true) {
      url += `@${this.person.preferredUsername}/feed/`;
    } else {
      url += `events/going/${this.person.feedTokens[0].token}/`;
    }
    return url + (format === "ics" ? "ics" : "atom");
  }

  async createToken(): Promise<void> {
    const { data } = await this.$apollo.mutate({
      mutation: CREATE_FEED_TOKEN_ACTOR,
      variables: { actor_id: this.person.id },
    });

    this.person.feedTokens.push(data);
  }
}
</script>
