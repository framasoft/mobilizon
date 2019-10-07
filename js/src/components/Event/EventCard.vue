<docs>
### EventCard

A simple card for an event

```vue
<EventCard
  :event="{ 
    title: 'Vue Styleguidist first meetup: learn the basics!',
    beginsOn: new Date(),
    tags: [
      {
        slug: 'test', title: 'Test'
      },
      {
        slug: 'mobilizon', title: 'Mobilizon'
      },
    ],
    organizerActor: {
      preferredUsername: 'tcit',
      name: 'Some Random Dude',
      domain: null
    }
  }"
  />
```
</docs>

<template>
  <router-link class="card" :to="{ name: 'Event', params: { uuid: event.uuid } }">
    <div class="card-image" v-if="!event.image">
      <figure class="image is-16by9">
        <div class="tag-container" v-if="event.tags">
          <b-tag v-for="tag in event.tags.slice(0, 3)" :key="tag.slug" type="is-secondary">{{ tag.title }}</b-tag>
        </div>
        <img src="https://picsum.photos/g/400/225/?random" />
      </figure>
    </div>
    <div class="content">
      <div class="title-wrapper">
        <div class="date-component">
          <date-calendar-icon v-if="!mergedOptions.hideDate" :date="event.beginsOn" />
        </div>
        <h2 class="title" ref="title">{{ event.title }}</h2>
      </div>
      <span class="organizer-place-wrapper">
        <span v-if="actorDisplayName && actorDisplayName !== '@'">{{ $t('By {name}', { name: actorDisplayName }) }}</span>
        <span v-if="event.physicalAddress && (event.physicalAddress.locality || event.physicalAddress.description)">
          - {{ event.physicalAddress.locality || event.physicalAddress.description }}
        </span>
      </span>
    </div>
<!--    <div v-if="!mergedOptions.hideDetails" class="details">-->
<!--      <div v-if="event.participants.length > 0 &&-->
<!--      mergedOptions.loggedPerson &&-->
<!--      event.participants[0].actor.id === mergedOptions.loggedPerson.id">-->
<!--        <b-tag type="is-info"><translate>Organizer</translate></b-tag>-->
<!--      </div>-->
<!--      <div v-else-if="event.participants.length === 1">-->
<!--        <translate-->
<!--                :translate-params="{name: event.participants[0].actor.preferredUsername}"-->
<!--        >{name} organizes this event</translate>-->
<!--      </div>-->
<!--      <div v-else>-->
<!--        <span v-for="participant in event.participants" :key="participant.actor.uuid">-->
<!--          {{ participant.actor.preferredUsername }}-->
<!--          <span v-if="participant.role === ParticipantRole.CREATOR">(organizer)</span>,-->
<!--          &lt;!&ndash; <translate-->
<!--            :translate-params="{name: participant.actor.preferredUsername}"-->
<!--          >&nbsp;{name} is in,</translate>&ndash;&gt;-->
<!--        </span>-->
<!--      </div>-->
    </router-link>
</template>

<script lang="ts">
import { IEvent, ParticipantRole } from '@/types/event.model';
import { Component, Prop, Vue } from 'vue-property-decorator';
import DateCalendarIcon from '@/components/Event/DateCalendarIcon.vue';
import { IActor, IPerson, Person } from '@/types/actor';
const lineClamp = require('line-clamp');

export interface IEventCardOptions {
  hideDate: boolean;
  loggedPerson: IPerson | boolean;
  hideDetails: boolean;
  organizerActor: IActor | null;
}

@Component({
  components: {
    DateCalendarIcon,
  },
  mounted() {
    lineClamp(this.$refs.title, 3);
  },
})
export default class EventCard extends Vue {
  @Prop({ required: true }) event!: IEvent;
  @Prop({ required: false }) options!: IEventCardOptions;

  ParticipantRole = ParticipantRole;

  defaultOptions: IEventCardOptions = {
    hideDate: false,
    loggedPerson: false,
    hideDetails: false,
    organizerActor: null,
  };

  get mergedOptions(): IEventCardOptions {
    return { ...this.defaultOptions, ...this.options };
  }

  get actorDisplayName(): string {
    const actor = Object.assign(new Person(), this.event.organizerActor || this.mergedOptions.organizerActor);
    return actor.displayName();
  }

}
</script>

<style lang="scss">
  @import "../../variables";

  a.card {
    border: none;
    background: $secondary;

    div.tag-container {
      position: absolute;
      top: 10px;
      right: 0;
      margin-right: -5px;
      z-index: 10;
      max-width: 40%;

      span.tag {
        margin: 5px auto;
        box-shadow: 0 0 5px 0 rgba(0, 0, 0, 1);
        /*word-break: break-all;*/
        text-overflow: ellipsis;
        overflow: hidden;
        display: block;
        /*text-align: right;*/
        font-size: 1em;
        /*padding: 0 1px;*/
        line-height: 1.75em;
      }
    }

    div.card-image {
      background: $secondary;
    }

    div.content {
      padding: 5px;
      background: $secondary;

      div.title-wrapper {
        display: flex;

        div.date-component {
          flex: 0;
          margin-right: 16px;
        }

        .title {
          font-weight: 400;
          line-height: 1em;
          font-size: 1.6em;
          padding-bottom: 5px;
          margin-top: auto;
        }
      }
      span.organizer-place-wrapper {
        display: flex;

        span:last-child {
          flex: 1;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }
      }
    }
  }

</style>
