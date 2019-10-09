<template>
    <main class="container">
        <b-tabs type="is-boxed" v-if="event">
            <b-tab-item>
                <template slot="header">
                    <b-icon icon="account-multiple"></b-icon>
                    <span>{{ $t('Participants')}} <b-tag rounded> {{ participantStats.approved }} </b-tag> </span>
                </template>
                <template>
                  <section v-if="participantsAndCreators.length > 0">
                      <h2 class="title">{{ $t('Participants') }}</h2>
                      <div class="columns">
                          <div class="column is-one-quarter-desktop" v-for="participant in participantsAndCreators" :key="participant.actor.id">
                              <participant-card
                                  :participant="participant"
                                  :accept="acceptParticipant"
                                  :reject="refuseParticipant"
                                  :exclude="refuseParticipant"
                              />
                          </div>
                      </div>
                  </section>
                </template>
            </b-tab-item>
            <b-tab-item :disabled="participantStats.unapproved === 0">
                <template slot="header">
                    <b-icon icon="account-multiple-plus"></b-icon>
                    <span>{{ $t('Requests') }} <b-tag rounded> {{ participantStats.unapproved }} </b-tag> </span>
                </template>
                <template>
                  <section v-if="queue.length > 0">
                      <h2 class="title">{{ $t('Waiting list') }}</h2>
                      <div class="columns">
                          <div class="column is-one-quarter-desktop" v-for="participant in queue" :key="participant.actor.id">
                              <participant-card
                                  :participant="participant"
                                  :accept="acceptParticipant"
                                  :reject="refuseParticipant"
                                  :exclude="refuseParticipant"
                              />
                          </div>
                      </div>
                  </section>
                </template>
            </b-tab-item>
            <b-tab-item :disabled="participantStats.rejected === 0">
                <template slot="header">
                    <b-icon icon="account-multiple-minus"></b-icon>
                    <span>{{ $t('Rejected')}} <b-tag rounded> {{ participantStats.rejected }} </b-tag> </span>
                </template>
                <template>
                  <section v-if="rejected.length > 0">
                      <h2 class="title">{{ $t('Rejected participations') }}</h2>
                      <div class="columns">
                          <div class="column is-one-quarter-desktop" v-for="participant in rejected" :key="participant.actor.id">
                              <participant-card
                                      :participant="participant"
                                      :accept="acceptParticipant"
                                      :reject="refuseParticipant"
                                      :exclude="refuseParticipant"
                              />
                          </div>
                      </div>
                  </section>
                </template>
            </b-tab-item>
        </b-tabs>
    </main>
</template>

<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import { IEvent, IParticipant, Participant, ParticipantRole } from '@/types/event.model';
import { UPDATE_PARTICIPANT, PARTICIPANTS } from '@/graphql/event';
import ParticipantCard from '@/components/Account/ParticipantCard.vue';
import { CURRENT_ACTOR_CLIENT } from '@/graphql/actor';
import { IPerson } from '@/types/actor';


@Component({
  components: {
    ParticipantCard,
  },
  apollo: {
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
    event: {
      query: PARTICIPANTS,
      variables() {
        return {
          uuid: this.eventId,
          page: 1,
          limit: 10,
          roles: [ParticipantRole.PARTICIPANT].join(),
          actorId: this.currentActor.id,
        };
      },
    },
    organizers: {
      query: PARTICIPANTS,
      variables() {
        return {
          uuid: this.eventId,
          page: 1,
          limit: 20,
          roles: [ParticipantRole.CREATOR].join(),
          actorId: this.currentActor.id,
        };
      },
      update: data => data.event.participants.map(participation => new Participant(participation)),
    },
    queue: {
      query: PARTICIPANTS,
      variables() {
        return {
          uuid: this.eventId,
          page: 1,
          limit: 20,
          roles: [ParticipantRole.NOT_APPROVED].join(),
          actorId: this.currentActor.id,
        };
      },
      update: data => data.event.participants.map(participation => new Participant(participation)),
    },
    rejected: {
      query: PARTICIPANTS,
      variables() {
        return {
          uuid: this.eventId,
          page: 1,
          limit: 20,
          roles: [ParticipantRole.REJECTED].join(),
          actorId: this.currentActor.id,
        };
      },
      update: data => data.event.participants.map(participation => new Participant(participation)),
    },
  },
})
export default class Participants extends Vue {
  @Prop({ required: true }) eventId!: string;
  page: number = 1;
  limit: number = 10;

  // participants: IParticipant[] = [];
  organizers: IParticipant[] = [];
  queue: IParticipant[] = [];
  rejected: IParticipant[] = [];
  event!: IEvent;

  ParticipantRole = ParticipantRole;
  currentActor!: IPerson;

  hasMoreParticipants: boolean = false;

  get participants(): IParticipant[] {
    return this.event.participants.map(participant => new Participant(participant));
  }

  get participantStats(): Object {
    return this.event.participantStats;
  }

  get participantsAndCreators(): IParticipant[] {
    if (this.event) {
      return [...this.organizers, ...this.participants];
    }
    return [];
  }

  loadMoreParticipants() {
    this.page += 1;
    this.$apollo.queries.participants.fetchMore({
      // New variables
      variables: {
        page: this.page,
        limit: this.limit,
      },
      // Transform the previous result with new data
      updateQuery: (previousResult, { fetchMoreResult }) => {
        const newParticipations = fetchMoreResult.event.participants;
        this.hasMoreParticipants = newParticipations.length === this.limit;

        return {
          loggedUser: {
            __typename: previousResult.event.__typename,
            participations: [...previousResult.event.participants, ...newParticipations],
          },
        };
      },
    });
  }

  async acceptParticipant(participant: IParticipant) {
    try {
      const { data } = await this.$apollo.mutate({
        mutation: UPDATE_PARTICIPANT,
        variables: {
          id: participant.id,
          moderatorActorId: this.currentActor.id,
          role: ParticipantRole.PARTICIPANT,
        },
      });
      if (data) {
        this.queue.filter(participant => participant !== data.updateParticipation.id);
        this.rejected.filter(participant => participant !== data.updateParticipation.id);
        this.participants.push(participant);
      }
    } catch (e) {
      console.error(e);
    }
  }

  async refuseParticipant(participant: IParticipant) {
    try {
      const { data } = await this.$apollo.mutate({
        mutation: UPDATE_PARTICIPANT,
        variables: {
          id: participant.id,
          moderatorActorId: this.currentActor.id,
          role: ParticipantRole.REJECTED,
        },
      });
      if (data) {
        this.participants.filter(participant => participant !== data.updateParticipation.id);
        this.queue.filter(participant => participant !== data.updateParticipation.id);
        this.rejected.push(participant);
      }
    } catch (e) {
      console.error(e);
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style lang="scss" scoped>
    section {
        padding: 1rem 0;
    }
</style>
<style lang="scss">
  nav.tabs li {
    margin: 3rem 0 0;
  }

  .tab-content {
    background: #fff;
  }
</style>
