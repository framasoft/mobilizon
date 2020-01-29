<template>
    <main class="container">
        <b-tabs type="is-boxed" v-if="event" v-model="activeTab">
            <b-tab-item>
                <template slot="header">
                    <b-icon icon="account-multiple" />
                    <span>{{ $t('Participants')}} <b-tag rounded> {{ participantStats.going }} </b-tag> </span>
                </template>
                <template>
                  <section v-if="participantsAndCreators.length > 0">
                      <h2 class="title">{{ $t('Participants') }}</h2>
                      <p v-if="confirmedAnonymousParticipantsCountCount > 1">
                          {{ $tc('And no anonymous participations|And one anonymous participation|And {count} anonymous participations', confirmedAnonymousParticipantsCountCount, { count: confirmedAnonymousParticipantsCountCount}) }}
                      </p>
                      <div class="columns is-multiline">
                          <div class="column is-one-quarter-desktop" v-for="participant in participantsAndCreators" :key="participant.actor.id">
                              <participant-card
                                  v-if="participant.actor.id !== config.anonymous.actorId"
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
            <b-tab-item :disabled="participantStats.notApproved === 0">
                <template slot="header">
                    <b-icon icon="account-multiple-plus" />
                    <span>{{ $t('Requests') }} <b-tag rounded> {{ participantStats.notApproved }} </b-tag> </span>
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
import { Component, Prop, Vue, Watch } from 'vue-property-decorator';
import { IEvent, IEventParticipantStats, IParticipant, Participant, ParticipantRole } from '@/types/event.model';
import { PARTICIPANTS, UPDATE_PARTICIPANT } from '@/graphql/event';
import ParticipantCard from '@/components/Account/ParticipantCard.vue';
import { CURRENT_ACTOR_CLIENT } from '@/graphql/actor';
import { IPerson } from '@/types/actor';
import { CONFIG } from '@/graphql/config';
import { IConfig } from '@/types/config.model';

@Component({
  components: {
    ParticipantCard,
  },
  apollo: {
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
    config: CONFIG,
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
      skip() {
        return !this.currentActor.id;
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
      skip() {
        return !this.currentActor.id;
      },
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
      skip() {
        return !this.currentActor.id;
      },
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
      skip() {
        return !this.currentActor.id;
      },
    },
  },
})
export default class Participants extends Vue {
  @Prop({ required: true }) eventId!: string;
  page: number = 1;
  limit: number = 10;

  organizers: IParticipant[] = [];
  queue: IParticipant[] = [];
  rejected: IParticipant[] = [];
  event!: IEvent;
  config!: IConfig;

  ParticipantRole = ParticipantRole;
  currentActor!: IPerson;

  hasMoreParticipants: boolean = false;
  activeTab: number = 0;

  get participantStats(): IEventParticipantStats | null {
    if (!this.event) return null;
    return this.event.participantStats;
  }

  get participantsAndCreators(): IParticipant[] {
    if (this.event) {
      return [...this.organizers, ...this.event.participants]
          .filter(participant => [ParticipantRole.PARTICIPANT, ParticipantRole.CREATOR].includes(participant.role));
    }
    return [];
  }

  get confirmedAnonymousParticipantsCountCount(): number {
    return this.participantsAndCreators.filter(({ actor: { id } }) => id === this.config.anonymous.actorId).length;
  }

  @Watch('participantStats', { deep: true })
  watchParticipantStats(stats: IEventParticipantStats) {
    if (!stats) return;
    if ((stats.notApproved === 0 && this.activeTab === 1) || stats.rejected === 0 && this.activeTab === 2 ) {
      this.activeTab = 0;
    }
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
        this.queue = this.queue.filter(participant => participant.id !== data.updateParticipation.id);
        this.rejected = this.rejected.filter(participant => participant.id !== data.updateParticipation.id);
        this.event.participantStats.going += 1;
        if (participant.role === ParticipantRole.NOT_APPROVED) {
          this.event.participantStats.notApproved -= 1;
        }
        if (participant.role === ParticipantRole.REJECTED) {
          this.event.participantStats.rejected -= 1;
        }
        participant.role = ParticipantRole.PARTICIPANT;
        this.event.participants.push(participant);
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
        this.event.participants = this.event.participants.filter(participant => participant.id !== data.updateParticipation.id);
        this.queue = this.queue.filter(participant => participant.id !== data.updateParticipation.id);
        this.event.participantStats.rejected += 1;
        if (participant.role === ParticipantRole.PARTICIPANT) {
          this.event.participantStats.participant -= 1;
          this.event.participantStats.going -= 1;
        }
        if (participant.role === ParticipantRole.NOT_APPROVED) {
          this.event.participantStats.notApproved -= 1;
        }
        participant.role = ParticipantRole.REJECTED;
        this.rejected = this.rejected.filter(participantIn => participantIn.id !== participant.id);
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
