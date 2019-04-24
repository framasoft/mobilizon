<template>
  <div>
    <b-loading :active.sync="$apollo.loading"></b-loading>
    <div v-if="event">
      <div class="header-picture container">
        <figure class="image is-3by1">
          <img src="https://picsum.photos/600/200/">
        </figure>
      </div>
        <section class="container">
          <div class="title-and-participate-button">
            <div class="title-wrapper">
              <div class="date-component">
                <date-calendar-icon :date="event.beginsOn"></date-calendar-icon>
              </div>
              <h1 class="title">{{ event.title }}</h1>
            </div>
            <div v-if="!actorIsOrganizer()" class="participate-button has-text-centered">
              <a v-if="!actorIsParticipant()" @click="joinEvent" class="button is-large is-primary is-rounded">
                <b-icon icon="circle-outline"></b-icon>
                <translate>Join</translate>
              </a>
              <a v-if="actorIsParticipant()" @click="leaveEvent" class="button is-large is-primary is-rounded">
                <b-icon icon="check-circle"></b-icon>
                <translate>Leave</translate>
              </a>
            </div>
          </div>
          <div class="metadata columns">
            <div class="column is-three-quarters-desktop">
              <p class="tags" v-if="event.category || event.tags.length > 0">
                <span class="tag" v-if="event.category">{{ event.category }}</span>
                <span class="tag" v-if="event.tags" v-for="tag in event.tags">{{ tag.title }}</span>
                <span class="visibility">
                  <translate v-if="event.visibility === EventVisibility.PUBLIC">public event</translate>
                </span>
              </p>
              <div class="date-and-add-to-calendar">
                <div class="date-and-privacy" v-if="event.beginsOn">
                  <b-icon icon="calendar-clock" />
                  <event-full-date :beginsOn="event.beginsOn" :endsOn="event.endsOn" />
                </div>
                <a class="add-to-calendar" @click="downloadIcsEvent()">
                  <b-icon icon="calendar-plus" />
                  <translate>Add to my calendar</translate>
                </a>
              </div>
              <p class="slug">
                {{ event.slug }}
              </p>
            </div>
            <div class="column sidebar">
              <div class="field has-addons" v-if="actorIsOrganizer()">
                <p class="control">
                  <router-link
                          class="button"
                          :to="{ name: 'EditEvent', params: {uuid: event.uuid}}"
                  >
                    <translate>Edit</translate>
                  </router-link>
                </p>
                <p class="control">
                  <a class="button is-danger" @click="deleteEvent()">
                    <translate>Delete</translate>
                  </a>
                </p>
              </div>
              <div class="address-wrapper">
                <b-icon icon="map" />
                <translate v-if="!event.physicalAddress">No address defined</translate>
                <div class="address" v-if="event.physicalAddress">
                  <address>
                    <span class="addressDescription">{{ event.physicalAddress.description }}</span>
                    <span>{{ event.physicalAddress.floor }} {{ event.physicalAddress.street }}</span>
                    <span>{{ event.physicalAddress.postal_code }} {{ event.physicalAddress.locality }}</span>
  <!--                  <span>{{ event.physicalAddress.region }} {{ event.physicalAddress.country }}</span>-->
                  </address>
                  <span class="map-show-button" @click="showMap = !showMap" v-if="event.physicalAddress && event.physicalAddress.geom">
                    <translate>Show map</translate>
                  </span>
                </div>
                <b-modal v-if="event.physicalAddress && event.physicalAddress.geom" :active.sync="showMap" :width="800" scroll="keep">
                  <div class="map">
                    <map-leaflet
                            :coords="event.physicalAddress.geom"
                            :popup="event.physicalAddress.description"
                    />
                  </div>
                </b-modal>
              </div>
              <div class="organizer">
                <router-link
                        :to="{name: 'Profile', params: { name: event.organizerActor.preferredUsername } }"
                >
                <translate
                        :translate-params="{name: event.organizerActor.name ? event.organizerActor.name : event.organizerActor.preferredUsername}"
                        v-if="event.organizerActor">By %{ name }</translate>
                  <figure v-if="event.organizerActor.avatarUrl" class="image is-48x48">
                    <img
                            class="is-rounded"
                            :src="event.organizerActor.avatarUrl"
                            :alt="$gettextInterpolate('%{actor}\'s avatar', {actor: event.organizerActor.preferredUsername})" />
                  </figure>
                </router-link>
              </div>
            </div>
          </div>
        </section>

<!--          <p v-if="actorIsOrganizer()">-->
<!--            <translate>You are an organizer.</translate>-->
<!--          </p>-->
<!--          <div v-else>-->
<!--            <p v-if="actorIsParticipant()">-->
<!--              <translate>You announced that you're going to this event.</translate>-->
<!--            </p>-->
<!--            <p v-else>-->
<!--              <translate>Are you going to this event?</translate><br />-->
<!--              <span>-->
<!--                <translate-->
<!--                        :translate-n="event.participants.length"-->
<!--                        translate-plural="%{event.participants.length} persons are going"-->
<!--                >-->
<!--                  One person is going.-->
<!--                </translate>-->
<!--              </span>-->
<!--            </p>-->
<!--          </div>-->
        <div class="description">
          <div class="description-container container">
            <h3 class="title">
              <translate>About this event</translate>
            </h3>
            <p v-if="!event.description">
              <translate>The event organizer didn't add any description.</translate>
            </p>
            <div class="columns" v-else="event.description">
              <div class="column is-half">
<!--                <vue-simple-markdown :source="event.description" />-->
                <p>
                  Lorem ipsum dolor sit amet, consectetur adipiscing elit.
                  Suspendisse vehicula ex dapibus augue volutpat, ultrices cursus mi rutrum.
                  Nunc ante nunc, facilisis a tellus quis, tempor mollis diam. Aenean consectetur quis est a ultrices.
                  Lorem ipsum dolor sit amet, consectetur adipiscing elit.
                </p>
                <p><a href="https://framasoft.org">https://framasoft.org</a>
                <p>
                  Nam sit amet est eget velit tristique commodo. Etiam sollicitudin dignissim diam, ut ultricies tortor.
                  Sed quis blandit diam, a tincidunt nunc. Donec tincidunt tristique neque at rhoncus. Ut eget vulputate felis.
                  Pellentesque nibh purus, viverra ac augue sed, iaculis feugiat velit. Nulla ut hendrerit elit.
                  Etiam at justo eu nunc tempus sagittis. Sed ac tincidunt tellus, sit amet luctus velit.
                  Nam ullamcorper eros eleifend, eleifend diam vitae, lobortis risus.
                </p>
                <p>
                  <em>
                    Curabitur rhoncus sapien tortor, vitae imperdiet massa scelerisque non.
                    Aliquam eu augue mi. Donec hendrerit lorem orci.
                  </em>
                </p>
                <p>
                  Donec volutpat, enim eu laoreet dictum, urna quam varius enim, eu convallis urna est vitae massa.
                  Morbi porttitor lacus a sem efficitur blandit. Mauris in est in quam tincidunt iaculis non vitae ipsum.
                  Phasellus eget velit tellus. Curabitur ac neque pharetra velit viverra mollis.
                </p>
                <img src="https://framasoft.org/img/biglogo-notxt.png" alt="logo Framasoft"/>
                <p>Aenean gravida, ante vitae aliquet aliquet, elit quam tristique orci, sit amet dictum lorem ipsum nec tortor.
                  Vestibulum est eros, faucibus et semper vel, dapibus ac est. Suspendisse potenti. Suspendisse potenti.
                  Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.
                  Nulla molestie nisi ac risus hendrerit, dapibus mattis sapien scelerisque.
                </p>
                <p>Maecenas id pretium justo, nec dignissim sapien. Mauris in venenatis odio, in congue augue. </p>
              </div>
            </div>
          </div>
        </div>
<!--      <section class="container">-->
<!--        <h2 class="title">Participants</h2>-->
<!--        <span v-if="event.participants.length === 0">No participants yet.</span>-->
<!--        <div class="columns">-->
<!--          <router-link-->
<!--            class="column"-->
<!--            v-for="participant in event.participants"-->
<!--            :key="participant.preferredUsername"-->
<!--            :to="{name: 'Profile', params: { name: participant.actor.preferredUsername }}"-->
<!--          >-->
<!--            <div>-->
<!--              <figure>-->
<!--                <img v-if="!participant.actor.avatarUrl" src="https://picsum.photos/125/125/">-->
<!--                <img v-else :src="participant.actor.avatarUrl">-->
<!--              </figure>-->
<!--              <span>{{ participant.actor.preferredUsername }}</span>-->
<!--            </div>-->
<!--          </router-link>-->
<!--        </div>-->
<!--      </section>-->
      <section class="share">
        <div class="container">
          <div class="columns">
            <div class="column is-half has-text-centered">
              <h3 class="title"><translate>Share this event</translate></h3>
              <div>
                <b-icon icon="mastodon" size="is-large" type="is-primary" />
                <a :href="facebookShareUrl" target="_blank" rel="nofollow noopener"><b-icon icon="facebook" size="is-large" type="is-primary" /></a>
                <a :href="twitterShareUrl" target="_blank" rel="nofollow noopener"><b-icon icon="twitter" size="is-large" type="is-primary" /></a>
                <a :href="emailShareUrl" target="_blank" rel="nofollow noopener"><b-icon icon="email" size="is-large" type="is-primary" /></a>
                <!--     TODO: mailto: links are not used anymore, we should provide a popup to redact a message instead    -->
                <a :href="linkedInShareUrl" target="_blank" rel="nofollow noopener"><b-icon icon="linkedin" size="is-large" type="is-primary" /></a>
              </div>
            </div>
            <hr />
            <div class="column is-half has-text-right add-to-calendar">
              <h3 @click="downloadIcsEvent()">
                <translate>Add to my calendar</translate>
              </h3>
            </div>
          </div>
        </div>
      </section>
      <section class="more-events container">
        <h3 class="title has-text-centered"><translate>These events may interest you</translate></h3>
        <div class="columns">
          <div class="column" v-for="relatedEvent in event.relatedEvents" :key="relatedEvent.uuid">
            <EventCard :event="relatedEvent" />
          </div>
        </div>
      </section>
      </div>
    </div>
</template>

<script lang="ts">
import { DELETE_EVENT, FETCH_EVENT, JOIN_EVENT, LEAVE_EVENT } from '@/graphql/event';
import { Component, Prop, Vue } from 'vue-property-decorator';
import { LOGGED_PERSON } from '@/graphql/actor';
import { EventVisibility, IEvent, IParticipant } from '@/types/event.model';
import { IPerson } from '@/types/actor.model';
import { RouteName } from '@/router';
import 'vue-simple-markdown/dist/vue-simple-markdown.css';
import { GRAPHQL_API_ENDPOINT } from '@/api/_entrypoint';
import DateCalendarIcon from '@/components/Event/DateCalendarIcon.vue';
import BIcon from 'buefy/src/components/icon/Icon.vue';
import EventCard from '@/components/Event/EventCard.vue';
import EventFullDate from '@/components/Event/EventFullDate.vue';

@Component({
  components: {
    EventFullDate,
    EventCard,
    BIcon,
    DateCalendarIcon,
    'map-leaflet': () => import('@/components/Map.vue'),
  },
  apollo: {
    event: {
      query: FETCH_EVENT,
      variables() {
        return {
          uuid: this.uuid,
        };
      },
    },
    loggedPerson: {
      query: LOGGED_PERSON,
    },
  },
})
export default class Event extends Vue {
  @Prop({ type: String, required: true }) uuid!: string;

  event!: IEvent;
  loggedPerson!: IPerson;
  validationSent: boolean = false;
  showMap: boolean = false;

  EventVisibility = EventVisibility;

  async deleteEvent() {
    const router = this.$router;

    try {
      await this.$apollo.mutate<IParticipant>({
        mutation: DELETE_EVENT,
        variables: {
          id: this.event.id,
          actorId: this.loggedPerson.id,
        },
      });

      router.push({ name: RouteName.EVENT });
    } catch (error) {
      console.error(error);
    }
  }

  async joinEvent() {
    try {
      await this.$apollo.mutate<IParticipant>({
        mutation: JOIN_EVENT,
        variables: {
          eventId: this.event.id,
          actorId: this.loggedPerson.id,
        },
        update: (store, { data: { joinEvent } }) => {
          const event = store.readQuery<IEvent>({ query: FETCH_EVENT });
          if (event === null) {
            console.error('Cannot update event participant cache, because of null value.');
            return;
          }

          event.participants = event.participants.concat([joinEvent]);

          store.writeQuery({ query: FETCH_EVENT, data: event });
        },
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
          eventId: this.event.id,
          actorId: this.loggedPerson.id,
        },
        update: (store, { data: { leaveEvent } }) => {
          const event = store.readQuery<IEvent>({ query: FETCH_EVENT });
          if (event === null) {
            console.error('Cannot update event participant cache, because of null value.');
            return;
          }

          event.participants = event.participants
            .filter(p => p.actor.id !== leaveEvent.actor.id);

          store.writeQuery({ query: FETCH_EVENT, data: event });
        },
      });
    } catch (error) {
      console.error(error);
    }
  }

  async downloadIcsEvent() {
    const data = await (await fetch(`${GRAPHQL_API_ENDPOINT}/events/${this.uuid}/export/ics`)).text();
    const blob = new Blob([data], { type: 'text/calendar' });
    const link = document.createElement('a');
    link.href = window.URL.createObjectURL(blob);
    link.download = `${this.event.title}.ics`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
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

  get twitterShareUrl(): string {
    return `https://twitter.com/intent/tweet?url=${encodeURIComponent(this.event.url)}&text=${this.event.title}`;
  }

  get facebookShareUrl(): string {
    return `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(this.event.url)}`;
  }

  get linkedInShareUrl(): string {
    return `https://www.linkedin.com/shareArticle?mini=true&url=${encodeURIComponent(this.event.url)}&title=${this.event.title}`;
  }

  get emailShareUrl(): string {
    return `mailto:?to=&body=${this.event.url}${encodeURIComponent('\n\n')}${this.event.description}&subject=${this.event.title}`;
  }
}
</script>
<style lang="scss" scoped>
  @import "../../variables";

  div.sidebar {
    display: flex;
    flex-wrap: wrap;
    flex-direction: column;

    position: relative;

    &::before {
      content: "";
      background: #B3B3B2;
      position: absolute;
      bottom: 30px;
      top: 30px;
      left: 0;
      height: calc(100% - 60px);
      width: 1px;
    }

    div.address-wrapper {
      display: flex;
      flex: 1;
      flex-wrap: wrap;

      div.address {
        flex: 1;

        .map-show-button {
          cursor: pointer;
        }

        address {
          font-style: normal;
          flex-wrap: wrap;
          display: flex;
          justify-content: flex-start;

          span.addressDescription {
            text-overflow: ellipsis;
            white-space: nowrap;
            flex: 1 0 auto;
            min-width: 100%;
          }

          :not(.addressDescription) {
            color: rgba(46, 62, 72, .6);
            flex: 1;
            min-width: 100%;
          }
        }
      }

      div.map {
        height: 900px;
        width: 100%;
        padding: 25px 5px 0;
      }
    }

    div.organizer {
      display: inline-flex;
      padding-top: 10px;

      a {
        color: #4a4a4a;

        span {
          line-height: 2.7rem;
          padding-right: 6px;
        }
      }
    }
  }

  div.title-and-participate-button {
    display: flex;
    flex-wrap: wrap;
    /*flex-flow: row wrap;*/
    justify-content: space-between;
    /*align-self: center;*/
    align-items: stretch;
    /*align-content: space-around;*/
    padding: 15px 10px 0;

    div.title-wrapper {
      display: flex;
      flex: 1 1 auto;


      div.date-component {
        margin-right: 16px;
      }

      h1.title {
        font-weight: normal;
        word-break: break-word;
        font-size: 1.7em;
      }
    }

    .participate-button {
      flex: 0 1 auto;
      display: inline-flex;

      a.button {
        margin: 0 auto;
      }
    }
  }

  div.metadata {
    padding: 0 10px;

    div.date-and-add-to-calendar {
      display: flex;
      flex-wrap: wrap;

      span.icon {
        margin-right: 5px;
      }

      div.date-and-privacy {
        color: $primary;
        padding: 0.3rem;
        background: $secondary;
        font-weight: bold;
      }

      a.add-to-calendar {
        flex: 0 0 auto;
        margin-left: 10px;
        color: #484849;

        &:hover {
          text-decoration: underline;
        }
      }
    }
  }

  p.tags {
    span {
      &.tag {
        &::before {
          content: '#';
        }
        text-transform: uppercase;
      }

      &.visibility::before {
        content: "⋅"
      }


      margin: auto 5px;
    }
    margin-bottom: 1rem;
  }

  h3.title {
    font-size: 3rem;
    font-weight: 300;
  }

  .description {
    padding-top: 10px;
    min-height: 40rem;
    background-repeat: no-repeat;
    background-size: 800px;
    background-position: 95% 101%;
    background-image: url('../../assets/texting.svg');
    border-top: solid 1px #111;
    border-bottom: solid 1px #111;

    p {
      margin: 10px auto;

      a {
        display: inline-block;
        padding: 0.3rem;
        background: $secondary;
        color: #111;
      }
    }
  }

  .share {
    border-bottom: solid 1px #111;

    .columns {

      & > * {
        padding: 10rem 0;
      }

      .add-to-calendar {
        background-repeat: no-repeat;
        background-size: 400px;
        background-position: 10% 50%;
        background-image: url('../../assets/undraw_events.svg');
        position: relative;

        &::before {
          content:"";
          background: #B3B3B2;
          position: absolute;
          bottom: 25%;
          left: 0;
          height: 40%;
          width: 1px;
        }


        h3 {
          display: block;
          color: $primary;
          font-size: 3rem;
          text-decoration: underline;
          text-decoration-color: $secondary;
          cursor: pointer;
          max-width: 20rem;
          margin-right: 0;
          margin-left: auto;
        }
      }
    }
  }

  .more-events {
    margin: 50px auto;
  }
</style>
