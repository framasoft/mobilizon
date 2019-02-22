<template>
  <div class="columns is-centered">
    <div class="column is-three-quarters">
      <b-loading :active.sync="$apollo.loading"></b-loading>
      <div class="card" v-if="event">
        <div class="card-image">
          <figure class="image is-4by3">
            <img src="https://picsum.photos/600/400/">
          </figure>
        </div>
        <div class="card-content">
          <span>{{ event.begins_on | formatDay }}</span>
          <span class="tag is-primary">{{ event.category.title }}</span>
          <h1 class="title">{{ event.title }}</h1>
          <router-link
            :to="{name: 'Profile', params: { name: event.organizerActor.preferredUsername } }"
          >
            <figure v-if="event.organizerActor.avatarUrl">
              <img :src="event.organizerActor.avatarUrl">
            </figure>
          </router-link>
          <span
            v-if="event.organizerActor"
          >Organisé par {{ event.organizerActor.name ? event.organizerActor.name : event.organizerActor.preferredUsername }}</span>
          <div class="field has-addons">
            <p class="control">
              <router-link
                v-if="actorIsOrganizer()"
                class="button"
                :to="{ name: 'EditEvent', params: {uuid: event.uuid}}"
              >
                <translate>Edit</translate>
              </router-link>
            </p>
            <p class="control">
              <a class="button" @click="downloadIcsEvent()">
                <translate>Download</translate>
              </a>
            </p>
            <p class="control">
              <a class="button is-danger" v-if="actorIsOrganizer()" @click="deleteEvent()">
                <translate>Delete</translate>
              </a>
            </p>
          </div>
          <div>
            <span>{{ event.begins_on | formatDate }} - {{ event.ends_on | formatDate }}</span>
          </div>
          <p v-if="actorIsOrganizer()">
            <translate>Vous êtes organisateur de cet événement.</translate>
          </p>
          <div v-else>
            <p v-if="actorIsParticipant()">
              <translate>Vous avez annoncé aller à cet événement.</translate>
            </p>
            <p v-else>
              Vous y allez ?
              <span>{{ event.participants.length }} personnes y vont.</span>
            </p>
          </div>
          <div v-if="!actorIsOrganizer()">
            <a v-if="!actorIsParticipant()" @click="joinEvent" class="button">
              <translate>Join</translate>
            </a>
            <a v-if="actorIsParticipant()" @click="leaveEvent" class="button">Leave</a>
          </div>
          <h2 class="subtitle">Details</h2>
          <p v-if="event.description">
            <vue-markdown :source="event.description"></vue-markdown>
          </p>
          <h2 class="subtitle">Participants</h2>
          <span v-if="event.participants.length === 0">No participants yet.</span>
          <div class="columns">
            <router-link
              class="card column"
              v-for="participant in event.participants"
              :key="participant.preferredUsername"
              :to="{name: 'Profile', params: { name: participant.actor.preferredUsername }}"
            >
              <div>
                <figure>
                  <img v-if="!participant.actor.avatarUrl" src="https://picsum.photos/125/125/">
                  <img v-else :src="participant.actor.avatarUrl">
                </figure>
                <span>{{ participant.actor.preferredUsername }}</span>
              </div>
            </router-link>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { DELETE_EVENT, FETCH_EVENT, LEAVE_EVENT } from '@/graphql/event';
import { Component, Prop, Vue } from 'vue-property-decorator';
import { LOGGED_PERSON } from '@/graphql/actor';
import { IEvent, IParticipant } from '@/types/event.model';
import { JOIN_EVENT } from '@/graphql/event';
import { IPerson } from '@/types/actor.model';

// No typings for this component, so we use require
const VueMarkdown = require('vue-markdown');

@Component({
  components: {
    VueMarkdown
  },
  apollo: {
    event: {
      query: FETCH_EVENT,
      variables() {
        return {
          uuid: this.uuid
        };
      }
    },
    loggedPerson: {
      query: LOGGED_PERSON
    }
  }
})
export default class Event extends Vue {
  @Prop({ type: String, required: true }) uuid!: string;

  event!: IEvent;
  loggedPerson!: IPerson;
  validationSent: boolean = false;

  async deleteEvent() {
    const router = this.$router;

    try {
      await this.$apollo.mutate<IParticipant>({
        mutation: DELETE_EVENT,
        variables: {
          id: this.event.id,
          actorId: this.loggedPerson.id,
        }
      });

      router.push({ name: 'EventList' })
    } catch (error) {
      console.error(error);
    }
  }

  async joinEvent() {
    try {
      await this.$apollo.mutate<IParticipant>({
        mutation: JOIN_EVENT,
        variables: {
          id: this.event.id,
          actorId: this.loggedPerson.id,
        },
        update: (store, { data: { joinEvent } }) => {
          const event = store.readQuery<IEvent>({ query: FETCH_EVENT });
          if (event === null) {
            console.error('Cannot update event participant cache, because of null value.')
            return
          }

          event.participants = event.participants.concat([ joinEvent ]);

          store.writeQuery({ query: FETCH_EVENT, data: event });
        }
      });
    } catch (error) {
      console.error(error);
    }
  }

  async leaveEvent() {
    try {
      await this.$apollo.mutate<IParticipant>({
        mutation: LEAVE_EVENT,
        variables: {
          id: this.event.id,
          actorId: this.loggedPerson.id,
        },
        update: (store, { data: { leaveEvent } }) => {
          const event = store.readQuery<IEvent>({ query: FETCH_EVENT });
          if (event === null) {
            console.error('Cannot update event participant cache, because of null value.');
            return
          }

          event.participants = event.participants
            .filter(p => p.actor.id !== leaveEvent.actor.id);

          store.writeQuery({ query: FETCH_EVENT, data: event });
        }
      });
    } catch (error) {
      console.error(error);
    }
  }

  downloadIcsEvent() {
    // FIXME: remove eventFetch
    // eventFetch(`/events/${this.uuid}/ics`, this.$store, { responseType: 'arraybuffer' })
    //   .then(response => response.text())
    //   .then((response) => {
    //     const blob = new Blob([ response ], { type: 'text/calendar' });
    //     const link = document.createElement('a');
    //     link.href = window.URL.createObjectURL(blob);
    //     link.download = `${this.event.title}.ics`;
    //     document.body.appendChild(link);
    //     link.click();
    //     document.body.removeChild(link);
    //   });
  }

  actorIsParticipant() {
    if (this.actorIsOrganizer()) return true;

    return this.loggedPerson &&
      this.event.participants
          .some(participant => participant.actor.id === this.loggedPerson.id);
  }

  actorIsOrganizer() {
    return this.loggedPerson &&
      this.loggedPerson.id === this.event.organizerActor.id;
  }
}
</script>
