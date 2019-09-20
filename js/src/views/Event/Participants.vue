<template>
    <main class="container">
        <b-tabs type="is-boxed" v-if="event">
            <b-tab-item>
                <template slot="header">
                    <b-icon icon="information-outline"></b-icon>
                    <span> Participants <b-tag rounded> {{ participantStats.approved }} </b-tag> </span>
                </template>
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
            </b-tab-item>
            <b-tab-item>
                <template slot="header">
                    <b-icon icon="source-pull"></b-icon>
                    <span> Demandes <b-tag rounded> {{ participantStats.unapproved }} </b-tag> </span>
                </template>
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
            </b-tab-item>
        </b-tabs>
    </main>
</template>

<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import { IEvent, IParticipant, Participant, ParticipantRole } from '@/types/event.model';
import { ACCEPT_PARTICIPANT, PARTICIPANTS, REJECT_PARTICIPANT } from '@/graphql/event';
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
        mutation: ACCEPT_PARTICIPANT,
        variables: {
          id: participant.id,
          moderatorActorId: this.currentActor.id,
        },
      });
      if (data) {
        console.log('accept', data);
        this.queue.filter(participant => participant !== data.acceptParticipation.id);
        this.participants.push(participant);
      }
    } catch (e) {
      console.error(e);
    }
  }

  async refuseParticipant(participant: IParticipant) {
    try {
      const { data } = await this.$apollo.mutate({
        mutation: REJECT_PARTICIPANT,
        variables: {
          id: participant.id,
          moderatorActorId: this.currentActor.id,
        },
      });
      if (data) {
        this.participants.filter(participant => participant !== data.rejectParticipation.id);
        this.queue.filter(participant => participant !== data.rejectParticipation.id);
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
        padding: 3rem 0;
    }
</style>
