<template>
  <div class="card">
    <div class="card-image" v-if="!event.image">
      <figure class="image is-4by3">
        <img src="https://picsum.photos/g/400/200/">
      </figure>
    </div>
    <div class="card-content">
      <div class="content">
        <router-link :to="{ name: 'Event', params:{ uuid: event.uuid } }">
          <h2 class="title">{{ event.title }}</h2>
        </router-link>
        <span>{{ event.begins_on | formatDay }}</span>
      </div>
      <div v-if="!hideDetails">
        <div v-if="event.participants.length === 1">
          <translate
            :translate-params="{name: event.participants[0].actor.preferredUsername}"
          >%{name} organizes this event</translate>
        </div>
        <div v-else>
          <span v-for="participant in event.participants" :key="participant.actor.uuid">
            {{ participant.actor.preferredUsername }}
            <span v-if="participant.role === ParticipantRole.CREATOR">(organizer)</span>,
            <!-- <translate
              :translate-params="{name: participant.actor.preferredUsername}"
            >&nbsp;%{name} is in,</translate>-->
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
  import {IEvent, ParticipantRole} from "@/types/event.model";
import { Component, Prop, Vue } from "vue-property-decorator";

@Component
export default class EventCard extends Vue {
  @Prop({ required: true }) event!: IEvent;
  @Prop({ default: false }) hideDetails!: boolean;

  data() {
    return {
      ParticipantRole: ParticipantRole
    }
  }
}
</script>
