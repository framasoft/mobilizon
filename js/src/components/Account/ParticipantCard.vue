<template>
  <article class="card">
    <div class="card-content">
      <div class="media">
        <div class="media-left" v-if="participant.actor.avatar">
          <figure class="image is-48x48">
            <img :src="participant.actor.avatar.url" />
          </figure>
        </div>
        <div class="media-content">
          <span class="title" ref="title">{{ actorDisplayName }}</span><br>
          <small class="has-text-grey">@{{ participant.actor.preferredUsername }}</small>
        </div>
      </div>
    </div>
    <footer class="card-footer">
    <b-button v-if="participant.role === ParticipantRole.NOT_APPROVED" @click="accept(participant)" type="is-success" class="card-footer-item">{{ $t('Approve') }}</b-button>
    <b-button v-if="participant.role === ParticipantRole.NOT_APPROVED" @click="reject(participant)" type="is-danger" class="card-footer-item">{{ $t('Reject')}} </b-button>
    <b-button v-if="participant.role === ParticipantRole.PARTICIPANT" @click="exclude(participant)" type="is-danger" class="card-footer-item">{{ $t('Exclude')}} </b-button>
    <span v-if="participant.role === ParticipantRole.CREATOR" class="card-footer-item">{{ $t('Creator')}} </span>
  </footer>
  </article>
</template>

<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import { IActor, IPerson, Person } from '@/types/actor';
import { IParticipant, ParticipantRole } from '@/types/event.model';

@Component
export default class ActorCard extends Vue {
  @Prop({ required: true }) participant!: IParticipant;
  @Prop({ type: Function }) accept;
  @Prop({ type: Function }) reject;
  @Prop({ type: Function }) exclude;

  ParticipantRole = ParticipantRole;

  get actorDisplayName(): string {
    const actor = new Person(this.participant.actor);
    return actor.displayName();
  }

}
</script>

<style lang="scss">
</style>
