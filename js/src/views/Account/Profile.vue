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

                        <b-dropdown hoverable has-link aria-role="list">
                            <button class="button is-info" slot="trigger">
                                <translate>Public feeds</translate>
                                <b-icon icon="menu-down"></b-icon>
                            </button>

                            <b-dropdown-item aria-role="listitem">
                                <a :href="feedUrls('atom', true)">
                                    <translate>Public RSS/Atom Feed</translate>
                                </a>
                            </b-dropdown-item>
                            <b-dropdown-item aria-role="listitem">
                                <a :href="feedUrls('ics', true)">
                                    <translate>Public iCal Feed</translate>
                                </a>
                            </b-dropdown-item>
                        </b-dropdown>

                        <b-dropdown hoverable has-link aria-role="list" v-if="person.feedTokens.length > 0">
                            <button class="button is-info" slot="trigger">
                                <translate>Private feeds</translate>
                                <b-icon icon="menu-down"></b-icon>
                            </button>

                            <b-dropdown-item aria-role="listitem">
                                <a :href="feedUrls('atom', false)">
                                    <translate>RSS/Atom Feed</translate>
                                </a>
                            </b-dropdown-item>
                            <b-dropdown-item aria-role="listitem">
                                <a :href="feedUrls('ics', false)">
                                    <translate>iCal Feed</translate>
                                </a>
                            </b-dropdown-item>
                        </b-dropdown>
                        <a class="button" v-else @click="createToken">
                            <translate>Create token</translate>
                        </a>
                    </div>
                    <section v-if="person.organizedEvents.length > 0">
                        <h2 class="subtitle">
                            <translate>Organized</translate>
                        </h2>
                        <div class="columns">
                            <EventCard
                                    v-for="event in person.organizedEvents"
                                    :event="event"
                                    :options="{ hideDetails: true }"
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
import { FETCH_PERSON, LOGGED_PERSON } from '@/graphql/actor';
import { Component, Prop, Vue, Watch } from 'vue-property-decorator';
import EventCard from '@/components/Event/EventCard.vue';
import { RouteName } from '@/router';
import { MOBILIZON_INSTANCE_HOST } from '@/api/_entrypoint';
import { IPerson } from '@/types/actor.model';
import { CREATE_FEED_TOKEN_ACTOR } from '@/graphql/feed_tokens';

@Component({
  apollo: {
    person: {
      query: FETCH_PERSON,
      variables() {
        return {
          name: this.$route.params.name,
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
export default class Profile extends Vue {
  @Prop({ type: String, required: true }) name!: string;

  person!: IPerson;

    // call again the method if the route changes
  @Watch('$route')
    onRouteChange() {
        // this.fetchData()
  }

  logoutUser() {
        // TODO : implement logout
    this.$router.push({ name: RouteName.HOME });
  }

  nl2br(text) {
    return text.replace(/(?:\r\n|\r|\n)/g, '<br>');
  }

  feedUrls(format, isPublic = true): string {
    let url = format === 'ics' ? 'webcal:' : '';
    url += `//${MOBILIZON_INSTANCE_HOST}/`;
    if (isPublic === true) {
      url += `@${this.person.preferredUsername}/feed/`;
    } else {
      url += `events/going/${this.person.feedTokens[0].token}/`;
    }
    return url + (format === 'ics' ? 'ics' : 'atom');
  }

  async createToken() {
    const { data } = await this.$apollo.mutate({
      mutation: CREATE_FEED_TOKEN_ACTOR,
      variables: { actor_id: this.person.id },
    });

    this.person.feedTokens.push(data);
  }
}
</script>
