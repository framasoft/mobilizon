import {ParticipantRole} from "@/types/event.model";
<template>
  <main class="container">
    <b-tabs type="is-boxed" v-if="event" v-model="activeTab">
      <b-tab-item>
        <template slot="header">
          <b-icon icon="account-multiple" />
          <span
            >{{ $t("Participants") }} <b-tag rounded> {{ participantStats.going }} </b-tag>
          </span>
        </template>
        <template>
          <section v-if="participants && participants.total > 0">
            <h2 class="title">{{ $t("Participants") }}</h2>
            <ParticipationTable
              :data="participants.elements"
              :accept-participant="acceptParticipant"
              :refuse-participant="refuseParticipant"
              :showRole="true"
              :total="participants.total"
              :perPage="PARTICIPANTS_PER_PAGE"
              @page-change="(page) => (participantPage = page)"
            />
          </section>
        </template>
      </b-tab-item>
      <b-tab-item :disabled="participantStats.notApproved === 0">
        <template slot="header">
          <b-icon icon="account-multiple-plus" />
          <span
            >{{ $t("Requests") }} <b-tag rounded> {{ participantStats.notApproved }} </b-tag>
          </span>
        </template>
        <template>
          <section v-if="queue && queue.total > 0">
            <h2 class="title">{{ $t("Waiting list") }}</h2>
            <ParticipationTable
              :data="queue.elements"
              :accept-participant="acceptParticipant"
              :refuse-participant="refuseParticipant"
              :total="queue.total"
              :perPage="PARTICIPANTS_PER_PAGE"
              @page-change="(page) => (queuePage = page)"
            />
          </section>
        </template>
      </b-tab-item>
      <b-tab-item :disabled="participantStats.rejected === 0">
        <template slot="header">
          <b-icon icon="account-multiple-minus"></b-icon>
          <span
            >{{ $t("Rejected") }} <b-tag rounded> {{ participantStats.rejected }} </b-tag>
          </span>
        </template>
        <template>
          <section v-if="rejected && rejected.total > 0">
            <h2 class="title">{{ $t("Rejected participations") }}</h2>
            <ParticipationTable
              :data="rejected.elements"
              :accept-participant="acceptParticipant"
              :refuse-participant="refuseParticipant"
              :total="rejected.total"
              :perPage="PARTICIPANTS_PER_PAGE"
              @page-change="(page) => (rejectedPage = page)"
            />
          </section>
        </template>
      </b-tab-item>
    </b-tabs>
  </main>
</template>

<script lang="ts">
import { Component, Prop, Vue, Watch } from "vue-property-decorator";
import {
  IEvent,
  IEventParticipantStats,
  IParticipant,
  Participant,
  ParticipantRole,
} from "../../types/event.model";
import { PARTICIPANTS, UPDATE_PARTICIPANT } from "../../graphql/event";
import ParticipantCard from "../../components/Account/ParticipantCard.vue";
import { CURRENT_ACTOR_CLIENT } from "../../graphql/actor";
import { IPerson } from "../../types/actor";
import { CONFIG } from "../../graphql/config";
import { IConfig } from "../../types/config.model";
import ParticipationTable from "../../components/Event/ParticipationTable.vue";
import { Paginate } from "../../types/paginate";

const PARTICIPANTS_PER_PAGE = 20;
const MESSAGE_ELLIPSIS_LENGTH = 130;

@Component({
  components: {
    ParticipationTable,
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
          limit: PARTICIPANTS_PER_PAGE,
          roles: [ParticipantRole.PARTICIPANT].join(),
          actorId: this.currentActor.id,
        };
      },
      skip() {
        return !this.currentActor.id;
      },
    },
    participants: {
      query: PARTICIPANTS,
      variables() {
        return {
          uuid: this.eventId,
          page: this.participantPage,
          limit: PARTICIPANTS_PER_PAGE,
          roles: [ParticipantRole.CREATOR, ParticipantRole.PARTICIPANT].join(),
          actorId: this.currentActor.id,
        };
      },
      update(data) {
        return this.dataTransform(data);
      },
      skip() {
        return !this.currentActor.id;
      },
    },
    queue: {
      query: PARTICIPANTS,
      variables() {
        return {
          uuid: this.eventId,
          page: this.queuePage,
          limit: PARTICIPANTS_PER_PAGE,
          roles: [ParticipantRole.NOT_APPROVED].join(),
          actorId: this.currentActor.id,
        };
      },
      update(data) {
        return this.dataTransform(data);
      },
      skip() {
        return !this.currentActor.id;
      },
    },
    rejected: {
      query: PARTICIPANTS,
      variables() {
        return {
          uuid: this.eventId,
          page: this.rejectedPage,
          limit: PARTICIPANTS_PER_PAGE,
          roles: [ParticipantRole.REJECTED].join(),
          actorId: this.currentActor.id,
        };
      },
      update(data) {
        return this.dataTransform(data);
      },
      skip() {
        return !this.currentActor.id;
      },
    },
  },
  filters: {
    ellipsize: (text?: string) => text && text.substr(0, MESSAGE_ELLIPSIS_LENGTH).concat("…"),
  },
})
export default class Participants extends Vue {
  @Prop({ required: true }) eventId!: string;

  page = 1;

  limit = 10;

  participants!: Paginate<IParticipant>;

  participantPage = 1;

  queue!: Paginate<IParticipant>;

  queuePage = 1;

  rejected!: Paginate<IParticipant>;

  rejectedPage = 1;

  event!: IEvent;

  config!: IConfig;

  ParticipantRole = ParticipantRole;

  currentActor!: IPerson;

  hasMoreParticipants = false;

  activeTab = 0;

  PARTICIPANTS_PER_PAGE = PARTICIPANTS_PER_PAGE;

  dataTransform(data: { event: IEvent }): Paginate<Participant> {
    return {
      total: data.event.participants.total,
      elements: data.event.participants.elements.map(
        (participation: IParticipant) => new Participant(participation)
      ),
    };
  }

  get participantStats(): IEventParticipantStats | null {
    if (!this.event) return null;
    return this.event.participantStats;
  }

  @Watch("participantStats", { deep: true })
  watchParticipantStats(stats: IEventParticipantStats) {
    if (!stats) return;
    if (
      (stats.notApproved === 0 && this.activeTab === 1) ||
      (stats.rejected === 0 && this.activeTab === 2)
    ) {
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
        this.queue.elements = this.queue.elements.filter(
          (participant) => participant.id !== data.updateParticipation.id
        );
        this.rejected.elements = this.rejected.elements.filter(
          (participant) => participant.id !== data.updateParticipation.id
        );
        this.event.participantStats.going += 1;
        if (participant.role === ParticipantRole.NOT_APPROVED) {
          this.event.participantStats.notApproved -= 1;
        }
        if (participant.role === ParticipantRole.REJECTED) {
          this.event.participantStats.rejected -= 1;
        }
        participant.role = ParticipantRole.PARTICIPANT;
        this.event.participants.elements.push(participant);
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
        this.event.participants.elements = this.event.participants.elements.filter(
          (participant) => participant.id !== data.updateParticipation.id
        );
        this.queue.elements = this.queue.elements.filter(
          (participant) => participant.id !== data.updateParticipation.id
        );
        this.event.participantStats.rejected += 1;
        if (participant.role === ParticipantRole.PARTICIPANT) {
          this.event.participantStats.participant -= 1;
          this.event.participantStats.going -= 1;
        }
        if (participant.role === ParticipantRole.NOT_APPROVED) {
          this.event.participantStats.notApproved -= 1;
        }
        participant.role = ParticipantRole.REJECTED;
        this.rejected.elements = this.rejected.elements.filter(
          (participantIn) => participantIn.id !== participant.id
        );
        this.rejected.elements.push(participant);
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

/deep/ .tabs.is-boxed {
  a {
    text-decoration: none;
  }
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
